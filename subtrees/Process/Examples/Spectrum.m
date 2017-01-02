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
      rejectParams 
      rawParams           % structure of parameters for mtspectrum
      baseParams
      filter
   end
   properties(Dependent)
      %Fs                 % Sampling Frequency
      nChannels           % unique & valid channels
      nSections           % valid sections
   end
   properties%(SetAccess = protected)
      labels_              % 
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
      function [c,f] = threshold(self,alpha)
         P = self.detail.values{1};
         c = gaminv(1-alpha,self.baseParams.alpha,1/self.baseParams.alpha);
         if nargout == 2
            f = self.detail.f(P>=c);
         end
      end
      
      function h = plotDiagnostics(self,singlefigure)
         if nargin < 2
            singlefigure = true;
         end

         f = self.raw.f;
         str = {'raw' 'base' 'baseFit' 'baseSmooth' 'detail'};
         bool = false(size(str));
         for i = 1:numel(str)
            if ~isempty(self.(str{i}))
               bool(i) = true;
               if self.nChannels == 1
                  P.(str{i}) = squeeze(self.(str{i}).values{1})';
               else
                  P.(str{i}) = squeeze(self.(str{i}).values{1});
               end
            end
         end

         if all(bool)
            n = 3;
         elseif all(bool([1 2 3 5]))
            n = 2;
         end
         
         xx = [0.5 max(f)];%[self.baseParams.fmin max(f)];
         flim = self.baseParams.fmax;
         if isempty(flim)
            flim = max(f);
         end
            
         shiftlog = 0;
         shiftlin = 0;
         for i = 1:self.nChannels
             switch self.baseParams.method
               case {'broken-power','broken-power1'}
                  if ~singlefigure
                     figure;
                     shiftlog = 0;
                     shiftlin = 0;
                  elseif i == 1
                     figure;
                  end
                  
                  h = subplot(n,2,1); hold on
                  plot(f,shiftlog + 10*log10(P.raw(:,i)),'color',self.labels_(i).color);
                  plot(f,shiftlog + 10*log10(P.baseFit(:,i)),'color',self.labels_(i).color);
                  plot(f,shiftlog + 10*log10(P.base(:,i)),'color',self.labels_(i).color);
                  axis tight;
                  yy = get(gca,'ylim');
                  plot([flim flim],yy,'k--');
                 
                  subplot(n,2,2); hold on
                  plot(log10(f),shiftlog + 10*log10(P.raw(:,i)),'color',self.labels_(i).color);
                  plot(log10(f),shiftlog + 10*log10(P.baseFit(:,i)),'color',self.labels_(i).color);
                  plot(log10(f),shiftlog + 10*log10(P.base(:,i)),'color',self.labels_(i).color);
                  axis tight;
                  yy = get(gca,'ylim'); %[min(10*log10(P.raw(:,i))) max(10*log10(P.raw(:,i)))];%
                  plot(log10([flim flim]),yy,'k--');
                  axis([log10(xx) yy]);
                  
                  %shiftlog = shiftlog + 10*log10(max(max(P.raw) - min(P.raw)));
                  shiftlog = shiftlog + max(10*log10(max(P.raw)) - 10*log10(min(P.raw)))/3;

                  if bool(4)
                     subplot(n,2,3); hold on
                     P2 = P.raw(:,i)./P.baseFit(:,i);
                     plot(f,P2);
                     plot(f,P.baseSmooth(:,i)); axis tight;
                     
                     subplot(n,2,4); hold on
                     plot(f,10*log10(P2));
                     plot(f,10*log10(P.baseSmooth(:,i)));
                     set(gca,'xscale','log'); axis tight;
                     yy = [min(10*log10(P2)) max(10*log10(P2))];%get(gca,'ylim');
                     plot([flim flim],yy,'k--');
                     axis([xx yy]);
                     j = 2;
                  else
                     j = 0;
                  end
                  
                  subplot(n,2,3+j); hold on
                  plot([xx(1) xx(end)],1 + [shiftlin shiftlin],'k');
                  plot(f,shiftlin + P.detail(:,i),'color',self.labels_(i).color);
                  axis tight; grid on
                  yy = get(gca,'ylim');
                  plot([flim flim],yy,'k--');
                  axis([xx yy]);
                  
                  subplot(n,2,4+j); hold on
                  plot([xx(1) xx(end)],1 + [shiftlin shiftlin],'k');
                  plot(f,shiftlin + P.detail(:,i),'color',self.labels_(i).color);
                  set(gca,'xscale','log'); axis tight; grid on
                  plot([flim flim],yy,'k--');
                  axis([xx yy]);
                  
                  shiftlin = shiftlin + 2;%max(max(P.detail) - min(P.detail));
                  
                  if ~singlefigure
                     fig.suptitle(self.labels_(i).name);
                  end
             end
         end
      end
      
      function h = plot(self)
         f = self.rawParams.f;
         alpha = self.baseParams.alpha;
         h = figure;
         plot(self.detail,'log',0,'handle',h,'title',true);
         for i = 1:self.nChannels
            subplot(self.nChannels,1,i); hold on;
            p = [.05 .5 .95 .9999];
            for j = 1:numel(p)
               c = gaminv(p(j),alpha(i),1/alpha(i));
               plot([f(2) f(end)],[c c],'-','Color',[1 0 0 0.25]);
               text(f(end),c,sprintf('%1.4f',p(j)));
            end
            set(gca,'xscale','log');
            
            h.Children(i).XLim(1) = self.baseParams.fmin;
            h.Children(i).YLim(2) = 5;
         end
      end
      
      function plot1(self,str,h,logy,shift,style)
         f = self.raw.f;
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
         f = f(ind);

         axes(h); hold on
         if logy
            P = 10*log10(squeeze(self.(str).values{1}));
         else
            P = squeeze(self.(str).values{1});
         end
         P = P(ind,:);
         
         shiftlog = 0;
         for i = 1:self.nChannels
            plot(f,shiftlog + P(:,i),...
               'color',self.labels_(i).color,'LineStyle',style);
            axis tight;
            set(gca,'xscale','log');
            shiftlog = shiftlog + shift;

            %yy = get(gca,'ylim');
            %plot([flim flim],yy,'k--');
         end
      end
      
      function self = compact(self)
         self.x_ = [];
      end
      
   end
   
end
