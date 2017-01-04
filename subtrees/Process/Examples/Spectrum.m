% TODO;
%  x multichannel
%  x expose baseline parameters
%  x implement irasa, not great
%  o during baseline estimation, consider extending edges to reduce edge effects
%  x remove line noise
%  o spike spectrum
%  o label checking
classdef Spectrum < hgsetget & matlab.mixin.Copyable
   properties
      input               % SampledProcess
      step                % size of sections (seconds)
      rejectParams        % currently, struct with field 'artifacts'
      rawParams           % structure of parameters for mtspectrum
      baseParams          % structure of parameters for base spectrum fitting
      filter              % magnitude response of ADC filter
   end
   properties(Dependent)
      %Fs                 % Sampling Frequency
      nChannels           % unique & valid channels
      nSections           % valid sections
   end
   properties%(SetAccess = protected)
      labels_             % metadata labels for channels
      raw                 % direct multitaper spectral estimate
      base                % estimate of base spectrum
      baseFit             % parametric fit to raw spectrum
      baseSmooth          % smoothed residual spectrum (raw/baseFit)
      detail              % estimate of detail spectrum (whitened & standardized)
   end
   properties(SetAccess = protected, Hidden)
      x_                  % sectioned data
      mask_               % boolean for valid sections
   end
   properties(SetAccess = immutable)
      version = '0.2.0'   % Version string
   end
   
   methods
      function self = Spectrum(varargin)
         p = inputParser;
         p.KeepUnmatched= false;
         p.FunctionName = 'Spectrum constructor';
         p.addParameter('input',[],@(x) isa(x,'SampledProcess') || ischar(x));
         p.addParameter('rejectParams',[]);
         p.addParameter('baseParams',struct('method','broken-power'),@isstruct);
         p.addParameter('rawParams',struct('hbw',0.5),@isstruct);
         p.addParameter('step',0,@(x) isscalar(x));
         p.addParameter('filter',[]);
         p.parse(varargin{:});
         par = p.Results;
         
         self.input = par.input;
         self.rejectParams = par.rejectParams;
         self.baseParams = par.baseParams;
         self.rawParams = par.rawParams;
         self.step = par.step;
         self.filter = par.filter;
      end
      
      function set.input(self,input)
         if isa(input,'SampledProcess')
            assert(numel(unique([input.Fs]))==1,'Fs must match for SampledProcess array.');
            assert(numel(unique([input.n]))==1,'# of channels must match for SampledProcess array.');
            
            % Check each SampledProcess has same labels in same order
            %self.nChannels = input(1).n;
%             assert(numel(unique(cat(1,input.labels),'rows'))==self.nChannels,...
%                'Labels must match for SampledProcess array.');
            
            self.input = copy(input);
         elseif ischar(input)
            self.input = input;
         end
      end
      
      function set.baseParams(self,baseParams)
         switch baseParams.method
            case {'broken-power','broken-power1'}
               if ~isfield(baseParams,'smoother')
                  baseParams.smoother = 'none'; % DEFAULT SMOOTHER
               end
               if isfield(baseParams,'beta0') && ~isempty(baseParams.beta0)
               else
                  baseParams.beta0 = [];
               end
               if ~isfield(baseParams,'fmin')
                  baseParams.fmin = 1;
               end
               if ~isfield(baseParams,'fmax')
                  baseParams.fmax = [];
               end
         end
         self.baseParams = baseParams;
      end
      
      function set.rawParams(self,params)
         self.rawParams = params;
      end
      
      function set.step(self,step)
         self.step = step;
      end
      
      function nSections = get.nSections(self)
         nSections = sum(self.mask_);
      end
      
      function nChannels = get.nChannels(self)
         nChannels = numel(self.labels_);
      end
      
      function bool = isRunnable(self)
         bool = ~isempty(self.input);
      end
      
      function self = run(self)
         if ~self.isRunnable
            error('No input signal');
         end
         
         self.estimateRaw();
         self.correctFilterGain();
         self.estimateBaseFit();
         self.estimateBaseSmooth();
         self.estimateDetail();
         self.standardize();
      end
      
      function self = refitBase(self)
         self.estimateBaseFit();
         self.estimateDetail();
         self.standardize();
      end
      
      %% Break input into sections
      function section(self)
         if self.step > 0 % section the data
            for i = 1:numel(self.input)
               win = [self.input(i).tStart:self.step:self.input(i).tEnd]';
               win = [win,win+self.step];
               win(win>self.input(i).tEnd) = self.input(i).tEnd;
               
               % Remove windows that don't match step-size.
               % This ensures that the DOF estimation is correct
               duration = diff(win,1,2);
               win(duration < self.step,:) = [];
               
               self.input(i).window = win;
               
               % Section matching artifacts EventProcess
               if isfield(self.rejectParams,'artifacts')
                  self.rejectParams.artifacts(i).window = win;
               end
            end
         end
         
         % Determine validity
         self.mask();
      end
      
      %% Create mask for bad channels/sections
      function mask(self)
         [s,labels] = extract(self.input);
         labels = labels{1}; % These already match
         
         if isfield(self.rejectParams,'artifacts')
            % Create a boolean matrix [nSections x nChannels] indicating
            % artifacts-free sections with quality>0
            artifacts = extract(self.rejectParams.artifacts);
            ind = [];
            for i = 1:numel(artifacts)
               for j = 1:numel(artifacts(i).values)
                  if isa(artifacts(i).values{j},'metadata.event.Artifact')...
                        &&(numel(artifacts(i).values{j})~=0)
                     temp = unique(cat(2,artifacts(i).values{j}(:).labels));
                     if ~isempty(temp)
                        [~,match] = intersect(labels,temp);
                     else
                        match = 1:numel(labels);
                     end
                     temp = ones(1,numel(labels));
                     temp(match) = 0;
                     ind = [ind ; temp];
                  else
                     ind = [ind ; ones(1,numel(labels))];
                  end
                  % Remove entire channel if quality <= 0
                  ind(end,:) = ind(end,:).*(self.input(i).quality>0);
               end
            end
         else
            ind = [];
            for i = 1:numel(self.input)
               ind = [ind ; ...
                  bsxfun(@times,ones(size(self.input(i).window,1),1),self.input(i).quality>0)];
            end
         end
         channelsToKeep = sum(ind,1)>0;
         
         temp = cat(1,s.values);
         
         if any(~channelsToKeep)
            for i = 1:numel(temp)
               temp{i}(:,~channelsToKeep) = [];
            end
            ind(:,~channelsToKeep) = [];
         end
         
         self.x_ = temp;
         self.mask_ = logical(ind);
         self.labels_ = labels(channelsToKeep);
      end
      
      %% Estimate raw spectrum
      function self = estimateRaw(self)
         self.section();

         if all(self.mask_)
            [out,par] = sig.mtspectrum(self.x_,...
               self.rawParams,'Fs',self.input(1).Fs);
         else
            [out,par] = sig.mtspectrum(self.x_,...
               self.rawParams,'Fs',self.input(1).Fs,'mask',self.mask_);
         end
         
         par = rmfield(par,{'dof','f'});
         P = zeros([1 size(out.P)]);
         P(1,:,:) = out.P; % format for SpectralProcess
         self.raw = SpectralProcess(P,...
            'f',out.f,'params',par,'tBlock',1,'tStep',1,...
            'labels',self.labels_,'tStart',0,'tEnd',1);
      end
      
      %% Remove attenuation due to ADC filter
      function self = correctFilterGain(self)
         if ~isempty(self.filter)
            f = self.raw.f;
            h = self.filter(f');
            h = repmat(h,[1 self.nChannels]);
            H = zeros(self.raw.dim{1});
            H(1,:,:) = h;
            self.raw.map(@(x) x./H);
            self.raw.fix();
         end
      end
      
      %% Estimate base spectrum
      function self = estimateBaseFit(self)
         import stat.baseline.*
         p = squeeze(self.raw.values{1});
         f = self.raw.f(:);
         if self.nChannels == 1
            p = p';
         end
         
         % TODO: Don't fit DC component TODO : nor nyquist?
         if ~isempty(self.baseParams.fmin) && ~isempty(self.baseParams.fmax)
            ind = (f>=self.baseParams.fmin) & (f<=self.baseParams.fmax);
         elseif ~isempty(self.baseParams.fmin) && isempty(self.baseParams.fmax)
            ind = (f>=self.baseParams.fmin);
         elseif isempty(self.baseParams.fmin) && ~isempty(self.baseParams.fmax)
            ind = (f<=self.baseParams.fmax);
         else
            ind = true(size(f));
         end
         fnz = f(ind);   % restricted frequencies
         pnz = p(ind,:); % restricted power
         
         [beta,fval,exitflag] = fit_smbrokenpl(fnz,pnz,...
            self.baseParams.method,self.baseParams.beta0);

         basefit = zeros(size(p));
         for i = 1:self.nChannels
            basefit(:,i) = smbrokenpl(beta(:,i),f);
         end
         
         P = zeros([1 size(basefit)]);
         P(1,:,:) = basefit; % format for SpectralProcess
         self.baseFit = SpectralProcess(P,...
            'f',f,'params',[],'tBlock',1,'tStep',1,...
            'labels',self.labels_,'tStart',0,'tEnd',1);
         self.baseParams.beta = beta;
         self.baseParams.exitflag = exitflag;
      end
      
      %% Smooth residuals
      function self = estimateBaseSmooth(self)
         p = squeeze(self.raw.values{1});
         f = self.raw.f(:);
         if isrow(p)
            p = p';
         end
         
         basefit = squeeze(self.baseFit.values{1});
         if self.nChannels == 1
            basefit = basefit';
         end
         basesmooth = ones(size(p));
         isSmooth = true;
         for i = 1:self.nChannels
            z = p(:,i)./basefit(:,i);
            z(isinf(z)) = median(z); % Trap divide by zeros
            switch self.baseParams.smoother
               case 'rlowess'
                  basesmooth(:,i) = smooth(z,numel(f)/2,'rlowess');
               case 'moving'
                  basesmooth(:,i) = smooth(z,numel(f)/2,'moving');
               case 'arpls'
                  basesmooth(:,i) = arpls(z,1e5);
               case 'median'
                  basesmooth(:,i) = medfilt1(z,floor(numel(f)/4),'truncate');
               otherwise
                  isSmooth = false;
            end
         end
         
         if isSmooth
            P(1,:,:) = basesmooth; % format for SpectralProcess
            self.baseSmooth = SpectralProcess(P,...
               'f',f,'params',[],'tBlock',1,'tStep',1,...
               'labels',self.labels_,'tStart',0,'tEnd',1);
         end
         
         % Combine fit with smoother for overall whitening transform
         base = basefit.*basesmooth;
         P = zeros([1 size(base)]);
         P(1,:,:) = base; % format for SpectralProcess
         self.base = SpectralProcess(P,...
            'f',f,'params',[],'tBlock',1,'tStep',1,...
            'labels',self.labels_,'tStart',0,'tEnd',1);
      end
      
      %% Estimate detail spectrum using whitening transform
      function self = estimateDetail(self)
         self.detail = copy(self.raw);
         temp = self.base.values{1};
         self.detail.map(@(x) x./temp);
         self.detail.fix();         
      end
      
      %% Rescale detail spectrum to unit variance white noise
      function self = standardize(self)
         % Approx alpha, this is not correct when section lengths differ
         alpha = self.nSections*mean(self.detail.params.k);
         f = self.raw.f;
         pw = squeeze(self.detail.values{1});
         if self.nChannels == 1
            pw = pw';
         end

         % Take only frequencies included in basefit
         if ~isempty(self.baseParams.fmin) && ~isempty(self.baseParams.fmax)
            ind = (f>=self.baseParams.fmin) & (f<=self.baseParams.fmax);
         elseif ~isempty(self.baseParams.fmin) && isempty(self.baseParams.fmax)
            ind = (f>=self.baseParams.fmin);
         elseif isempty(self.baseParams.fmin) && ~isempty(self.baseParams.fmax)
            ind = (f<=self.baseParams.fmax);
         else
            ind = true(size(f));
         end

         % Match to lower 5% quantile of expected distribution for white noise
         for i = 1:self.nChannels
            Q(i) = gaminv(0.05,alpha(i),1/alpha(i)) ./ (quantile(pw(ind,i),0.05));
         end
         if self.nChannels > 1
            self.detail.map(@(x) x.*reshape(repmat(Q,numel(f),1),[1 numel(f) self.nChannels]));
         else
            self.detail.map(@(x) Q*x);
         end
         self.detail.fix();
         
         self.baseParams.alpha = alpha;
         self.baseParams.Q = Q;
      end
      
      %% Threshold power at significance alpha
      function [c,fsig] = threshold(self,alpha)
         [P,f,labels] = self.extract('psd','detail','dB',false);
         c = gaminv(1-alpha,self.baseParams.alpha,1./self.baseParams.alpha);
         if nargout == 2
            for i = 1:size(P,2)
               fsig{i} = f(P(:,i)>=c(i));
            end
         end
      end
      
      function [P,f] = statInBand(self,varargin)
         p = inputParser;
         p.KeepUnmatched = true;
         p.FunctionName = 'Spectrum statInBand method';
         %p.addParameter('dB',false,@(x) isnumeric(x) || islogical(x));
         p.addParameter('band',[],@(x) isnumeric(x) && (size(x,2)==2));
         p.addParameter('exclude',[],@(x) isnumeric(x) && (size(x,2)==2));
         %p.addParameter('psd','raw',@(x) ischar(x));
         p.addParameter('stat','mean',@(x) ischar(x));
         %p.addParameter('normalize',[]);
         p.parse(varargin{:});
         par = p.Results;
                  
         [P,f,labels] = extract(self,p.Unmatched);
         
         f = self.raw.f;
         P = zeros(size(par.band,1),self.nChannels);
         tempP = squeeze(self.(par.psd).values{1});
         
         if ~isempty(par.exclude)
            exclude = zeros(numel(f),size(par.exclude,1));
            for i = 1:size(par.exclude)
               exclude(:,i) = (f>=par.exclude(i,1)) & (f<=par.exclude(i,2));
            end
            exclude = logical(sum(exclude,2))';
         else
            exclude = false(1,numel(f));
         end
         
         for i = 1:size(par.band,1)
            ind = (f>=par.band(i,1)) & (f<=par.band(i,2));
            P(i,:) = mean(tempP(ind&~exclude,:));
         end
      end
      
      function P = meanInBand(self,varargin)
         p = inputParser;
         p.KeepUnmatched = true;
         p.FunctionName = 'Spectrum toArray method';
         p.addParameter('dB',false,@(x) isnumeric(x) || islogical(x));
         p.addParameter('band',[],@(x) isnumeric(x) && (size(x,2)==2));
         p.addParameter('exclude',[],@(x) isnumeric(x) && (size(x,2)==2));
         p.addParameter('psd','raw',@(x) ischar(x));
         p.parse(varargin{:});
         par = p.Results;
                  
         f = self.raw.f;
         P = zeros(size(par.band,1),self.nChannels);
         temp = squeeze(self.(par.psd).values{1});
         if ~isempty(par.exclude)
            exclude = zeros(numel(f),size(par.exclude,1));
            for i = 1:size(par.exclude)
               exclude(:,i) = (f>=par.exclude(i,1)) & (f<=par.exclude(i,2));
            end
            exclude = logical(sum(exclude,2))';
         else
            exclude = false(1,numel(f));
         end
         
         for i = 1:size(par.band,1)
            ind = (f>=par.band(i,1)) & (f<=par.band(i,2));
            P(i,:) = mean(temp(ind&~exclude,:));
         end
         
         if nargout == 0
            sep = 2;
            self.plot('psd',par.psd,'sep',sep,'logy',false,'label',true,'percentile',0.5);
            shift = 0;
            for i = 1:size(P,2)
               for j = 1:size(par.band,1)
                  plot([par.band(j,1) par.band(j,2)],[P(j,i) P(j,i)] + shift,'-',...
                     'color',self.labels_(i).color);
               end
               shift = shift + sep;
            end
         end
      end
      
      function P = maxInBand(self,varargin)
         p = inputParser;
         p.KeepUnmatched = true;
         p.FunctionName = 'Spectrum toArray method';
         p.addParameter('dB',false,@(x) isnumeric(x) || islogical(x));
         p.addParameter('band',[],@(x) isnumeric(x) && (size(x,2)==2));
         p.addParameter('exclude',[],@(x) isnumeric(x) && (size(x,2)==2));
         p.addParameter('psd','raw',@(x) ischar(x));
         p.parse(varargin{:});
         par = p.Results;
                  
         f = self.raw.f;
         P = zeros(size(par.band,1),self.nChannels);
         temp = squeeze(self.(par.psd).values{1});
         if ~isempty(par.exclude)
            exclude = zeros(numel(f),size(par.exclude,1));
            for i = 1:size(par.exclude)
               exclude(:,i) = (f>=par.exclude(i,1)) & (f<=par.exclude(i,2));
            end
            exclude = logical(sum(exclude,2))';
         else
            exclude = false(1,numel(f));
         end
         
         for i = 1:size(par.band,1)
            ind = (f>=par.band(i,1)) & (f<=par.band(i,2));
            P(i,:) = max(temp(ind&~exclude,:));
         end
         
         if nargout == 0
            sep = 2;
            self.plot('psd',par.psd,'sep',sep,'logy',false,'label',true,'percentile',0.5);
            shift = 0;
            for i = 1:size(P,2)
               for j = 1:size(par.band,1)
                  plot([par.band(j,1) par.band(j,2)],[P(j,i) P(j,i)] + shift,'-',...
                     'color',self.labels_(i).color);
               end
               shift = shift + sep;
            end
         end
      end
      
      
      function [P,f,labels] = extract(self,varargin)
         p = inputParser;
         p.KeepUnmatched = true;
         p.FunctionName = 'Spectrum extract method';
         p.addParameter('dB',false,@(x) isnumeric(x) || islogical(x));
         p.addParameter('fmin',[],@(x) isscalar(x) || isempty(x));
         p.addParameter('fmax',[],@(x) isscalar(x) || isempty(x));
         p.addParameter('psd','raw',@(x) ischar(x));
         p.addParameter('f',[],@(x) isvector(x));
         p.addParameter('normalize',[]);
         p.parse(varargin{:});
         par = p.Results;
                  
         if isempty(par.f)
            f = self.raw.f;
            if isempty(par.fmin) && ~isempty(self.baseParams.fmin)
               fmin = self.baseParams.fmin;
            elseif ~isempty(par.fmin)
               fmin = par.fmin;
            else
               fmin = f(1);
            end
            
            if isempty(par.fmax) && ~isempty(self.baseParams.fmax)
               fmax = self.baseParams.fmax;
            elseif ~isempty(par.fmin)
               fmax = par.fmax;
            else
               fmax = f(end);
            end
            
            ind = (f>=fmin) & (f<=fmax);
            f = f(ind);
            P = squeeze(self.(par.psd).values{1});
            if self.nChannels == 1
               P = P';
            end
            P = P(ind,:);
         else
            %% Assumes we've always sampled frequencies with same dF (spacing)
            f = self.raw.f;
            % Index into actual frequency vector
            fmin = max(par.f(1),self.baseParams.fmin);
            fmax = min(par.f(end),self.baseParams.fmax);
            ind = (f>=fmin) & (f<=fmax);
            
            % Index into requested frequency vector
            fmin = max(par.f(1),self.baseParams.fmin);%f(1);
            fmax = min(par.f(end),self.baseParams.fmax);%f(end);
            ind2 = (par.f>=fmin) & (par.f<=fmax);
            
            temp = squeeze(self.(par.psd).values{1});
            if self.nChannels == 1
               temp = temp';
            end
            P = nan(numel(par.f),numel(self.labels_));
            P(ind2,:) = temp(ind,:);
            f = par.f;
         end

         if par.dB
            P = 10*log10(P);
         end
         
         if ~isempty(par.normalize)
            % use extract here so that normalization frequency range can be
            % different from requested frequency range
            [Pnorm,fnorm] = extract(self,'psd',par.psd,'dB',par.dB,...
               'fmin',par.normalize.fmin,'fmax',par.normalize.fmax);
            df = mean(diff(fnorm));
            switch par.normalize.method
               case 'integral'
                  P = bsxfun(@rdivide,P,df*trapz(Pnorm));
               case 'mean'
                  P = bsxfun(@rdivide,P,mean(Pnorm));
               otherwise
                  error('Unknown normalization method');
            end
         end
         
         labels = self.labels_;
      end
      
      function out = findpeaks(self,varargin)
         p = inputParser;
         p.KeepUnmatched = true;
         p.FunctionName = 'Spectrum findpeaks method';
         p.addParameter('dB',false,@(x) isnumeric(x) || islogical(x));
         p.addParameter('fmin',[],@(x) isscalar(x));
         p.addParameter('fmax',[],@(x) isscalar(x));
         p.addParameter('psd','raw',@(x) ischar(x));
         p.parse(varargin{:});
         par = p.Results;
         
         if isempty(fieldnames(p.Unmatched))
            par2 = struct('MinPeakWidth',0.25,'MinPeakProminence',0.35);
            par2.MinPeakHeight = mean(threshold(self,0.01));
         else
            par2 = p.Unmatched;
         end
         
         [P,f,labels] = extract(self,'fmin',par.fmin,'fmax',par.fmax,'psd',par.psd,'dB',par.dB);
         
         pks = cell(size(labels));
         locs = cell(size(labels));
         for i = 1:size(P,2)
            [pks{i},locs{i}] = findpeaks(P(:,i),f,par2);
         end

         if nargout == 0
            sep = 1;
            self.plot('psd',par.psd,'fmin',par.fmin,'fmax',par.fmax,'sep',sep,...
               'logy',false,'label',true);
            shift = 0;
            for i = 1:size(P,2)
               plot(locs{i},pks{i} + shift,'v','markersize',8,...
                  'Markerfacecolor',labels(i).color,'Markeredgecolor',labels(i).color);
               shift = shift + sep;
            end
         end
      end
      
      %%
      function h = plotDiagnostics(self)
         f = self.raw.f;
         fmin = 0.5;%f(1);
         fmax = f(end);
         
         figure;
         h = subplot(2,2,1);
         self.plot('handle',h,'psd','raw','sep',10,'logx',false,'fmin',fmin,'fmax',fmax);
         self.plot('handle',h,'psd','base','sep',10,'logx',false,'fmin',fmin,'fmax',fmax);
         if ~isempty(self.baseParams.fmax)
            yy = get(gca,'ylim');
            plot([self.baseParams.fmax self.baseParams.fmax],yy,'k--');
         end
         grid on;
         
         h = subplot(2,2,2);
         self.plot('handle',h,'psd','raw','sep',10,'fmin',fmin,'fmax',fmax);
         self.plot('handle',h,'psd','base','sep',10,'fmin',fmin,'fmax',fmax,'label',true);
         if ~isempty(self.baseParams.fmax)
            yy = get(gca,'ylim');
            plot([self.baseParams.fmax self.baseParams.fmax],yy,'k--');
         end
         grid on;
         
         h = subplot(2,2,3);
         self.plot('handle',h,'psd','detail','sep',4,'logy',false,'logx',false,...
            'percentile',[0.5],'fmin',fmin,'fmax',fmax,'vline',[4 8 12 20 30 70]);
         
         h = subplot(2,2,4);
         self.plot('handle',h,'psd','detail','sep',4,'logy',false,...
            'percentile',[0.9999],'fmin',fmin,'fmax',fmax,'vline',[4 8 12 20 30 70]);
      end
      
      %% Plot all channels on one axis
      % TODO
      %   o add masking
      function h = plot(self,varargin)
         p = inputParser;
         p.KeepUnmatched = true;
         p.FunctionName = 'Spectrum plot method';
         p.addParameter('handle',[],@(x) isnumeric(x) || ishandle(x));
         p.addParameter('stack',true,@(x) isnumeric(x) || islogical(x));
         p.addParameter('sep',3,@(x) isscalar(x));
         p.addParameter('fmin',[],@(x) isscalar(x));
         p.addParameter('fmax',[],@(x) isscalar(x));
         p.addParameter('logy',true,@(x) isnumeric(x) || islogical(x));
         p.addParameter('logx',true,@(x) isnumeric(x) || islogical(x));
         p.addParameter('label',false,@(x) isnumeric(x) || islogical(x));
         p.addParameter('hline',[],@(x) isnumeric(x));
         p.addParameter('vline',[],@(x) isnumeric(x));
         p.addParameter('percentile',[],@(x) isnumeric(x));
         p.addParameter('psd','raw',@(x) ischar(x));
         p.parse(varargin{:});
         par = p.Results;
         
         if isempty(par.handle)
            figure;
            h = axes(); hold on
         else
            axes(par.handle); hold on
         end
                  
         f = self.raw.f;
         if isempty(par.fmin) && ~isempty(self.baseParams.fmin)
            fmin = self.baseParams.fmin;
         elseif ~isempty(par.fmin)
            fmin = par.fmin;
         else
            fmin = f(1);
         end
         
         if isempty(par.fmax) && ~isempty(self.baseParams.fmax)
            fmax = self.baseParams.fmax;
         elseif ~isempty(par.fmin)
            fmax = par.fmax;
         else
            fmax = f(end);
         end
         
         ind = (f>=fmin) & (f<=fmax);
         f = f(ind);

         if par.logy
            P = 10*log10(squeeze(self.(par.psd).values{1}));
         else
            P = squeeze(self.(par.psd).values{1});
         end
         P = P(ind,:);
         
         shift = 0;
         alpha = self.baseParams.alpha;
         for i = 1:self.nChannels
            plot(f,shift + P(:,i),...
               'color',self.labels_(i).color,p.Unmatched);
            axis tight;
            if par.logx
               set(gca,'xscale','log');
            end

            if ~isempty(par.hline)
               plot([fmin fmax],shift + [par.hline par.hline],'-','Color',[0 0 0 0.25]);
            end
            
            if ~isempty(par.percentile)
               for j = 1:numel(par.percentile)
                  c = gaminv(par.percentile(j),alpha(i),1/alpha(i));
                  plot([fmin fmax],shift + [c c],'-','Color',[1 0 0 0.25]);
                  text(fmax,shift + c,sprintf('%1.4f',par.percentile(j)));
               end
            end
            
            if par.label
               text(fmax,shift+ P(end,i),self.labels_(i).name,...
                  'Color',self.labels_(i).color,'VerticalAlignment','middle');
            end
            
            shift = shift + par.sep;
         end
         
         if ~isempty(par.vline)
            yy = get(gca,'ylim');
            for i = 1:numel(par.vline)
               plot([par.vline(i) par.vline(i)],yy,'Color',[0 0 0 0.25]);
               text(par.vline(i),yy(2),sprintf('%g',par.vline(i)),...
                  'VerticalAlignment','bottom','HorizontalAlignment','center');
            end
         end
         
      end
      
      function self = compact(self)
         self.x_ = [];
      end
      
   end
   
end
