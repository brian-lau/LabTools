% TODO;
%  x multichannel
%  o expose baseline parameters
%  x implement irasa, not great
%  o during baseline estimation, consider extending edges to reduce edge effects
%  x remove line noise
%  o spike spectrum
classdef Spectrum < hgsetget & matlab.mixin.Copyable
   properties
      
      input % SampledProcess
      nChannels
      step
      nSections
      
      rejectParams
      
      raw   % direct multitaper spectral estimate
      rawParams %
      base  % estimate of base spectrum
      baseFit
      baseSmooth
      baseParams
      detail % estimate of detail spectrum (whitened & standardized)
      
      verbose
      
      x_
      mask_
      labels_
   end
   
   methods
      function self = Spectrum(varargin)
         p = inputParser;
         p.KeepUnmatched= false;
         p.FunctionName = 'Spectrum constructor';
         p.addParameter('input',[],@(x) isa(x,'SampledProcess'));
         p.addParameter('rejectParams',[]);
         p.addParameter('baseParams',struct('method','broken-power'),@isstruct);
         p.addParameter('rawParams',struct('hbw',0.5),@isstruct);
         p.addParameter('verbose',false,@(x) isscalar(x) && islogical(x));
         p.addParameter('step',0,@(x) isscalar(x));
         p.parse(varargin{:});
         par = p.Results;
         
         self.input = par.input;
         self.rejectParams = par.rejectParams;
         self.baseParams = par.baseParams;
         self.rawParams = par.rawParams;
         self.verbose = par.verbose;
         self.step = par.step;
      end
      
      function set.input(self,input)
         assert(numel(unique([input.Fs]))==1,'Fs must match for SampledProcess array.');
         assert(numel(unique([input.n]))==1,'# of channels must match for SampledProcess array.');
         
         self.nChannels = input(1).n;
         assert(numel(unique(cat(1,input.labels),'rows'))==self.nChannels,...
            'Labels must match for SampledProcess array.');
         
         self.input = copy(input);
         
         % Remove previous estimates
         self.raw = [];
         self.base = [];
         self.detail = [];
      end
      
      function set.baseParams(self,baseParams)
         switch baseParams.method
            case 'broken-power'
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
         params.Fs = self.input(1).Fs;
         self.rawParams = params;
      end
      
      function set.step(self,step)
         self.step = step;
      end
      
      function section(self)
         if self.step > 0 % section the data
            for i = 1:numel(self.input)
               win = [self.input(i).tStart:self.step:self.input(i).tEnd]';
               win = [win,win+self.step];
               win(win>self.input(i).tEnd) = self.input(i).tEnd;
               
               % Remove windows that don't match step-size. This ensures
               % that the DOF estimation is correct
               duration = diff(win,1,2);
               win(duration < self.step,:) = [];
               
               self.input(i).window = win;
               
               % Section matching artifacts EventProcess
               if isfield(self.rejectParams,'artifacts')
                  self.rejectParams.artifacts(i).window = win;
               end
            end
         end
         
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
         self.mask_ = ind;
         self.labels_ = labels(channelsToKeep);
         self.nChannels = numel(self.labels_);
         
         self.nSections = sum(ind);
      end
      
      
      function bool = isRunnable(self)
         bool = ~isempty(self.input);
      end
      
      function run(self)
         if ~self.isRunnable
            error('No input signal');
         end
         
         self.estimateRaw();
         self.estimateBaseFit();
         self.estimateBaseSmooth();
         %self.combineBase();
         %self.estimateDetail();
         self.standardize();
      end
      
      %% Estimate raw spectrum
      function self = estimateRaw(self)
         self.section();

         [out,par] = sig.mtspectrum(self.x_,self.rawParams);
         
         P = zeros([1 size(out.P)]);
         P(1,:,:) = out.P; % format for SpectralProcess
         self.raw = SpectralProcess(P,...
            'f',out.f,'params',par,'tBlock',1,'tStep',1,...
            'labels',self.labels_,'tStart',0,'tEnd',1);
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
            end
         end
         
         P(1,:,:) = basesmooth; % format for SpectralProcess
         self.baseSmooth = SpectralProcess(P,...
            'f',f,'params',[],'tBlock',1,'tStep',1,...
            'labels',self.labels_,'tStart',0,'tEnd',1);
         
         % Combine fit with smoother for overall whitening transform
         base = basefit.*basesmooth;
         P = zeros([1 size(base)]);
         P(1,:,:) = base; % format for SpectralProcess
         self.base = SpectralProcess(P,...
            'f',f,'params',[],'tBlock',1,'tStep',1,...
            'labels',self.labels_,'tStart',0,'tEnd',1);
         
         % Estimate detail spectrum using whitening transform
         self.detail = copy(self.raw);
         temp = reshape(base,[1 numel(f) self.nChannels]);
         self.detail.map(@(x) x./temp);
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
         
         self.baseParams.alpha = alpha;
         self.baseParams.Q = Q;
      end
      
      function [c,f] = threshold(self,alpha)
         P = self.detail.values{1};
         c = gaminv(1-alpha,self.baseParams.alpha,1/self.baseParams.alpha);
         if nargout == 2
            f = self.detail.f(P>=c);
         end
      end
      
      function h = plotDiagnostics(self)
         f = self.raw.f;
         P = squeeze(self.raw.values{1});
         Pstan = squeeze(self.detail.values{1});
         Q = self.baseParams.Q;
         base = squeeze(self.base.values{1});
         baseFit = squeeze(self.baseFit.values{1});
         baseSmooth = squeeze(self.baseSmooth.values{1});
         if self.nChannels == 1
            P = P';
            Pstan = Pstan';
            base = base';
            baseFit = baseFit';
            baseSmooth = baseSmooth';
         end
         
         for i = 1:self.nChannels
            switch self.baseParams.method
               case {'broken-power'}
                  figure;
                  h = subplot(321); hold on
                  plot(f,P(:,i));
                  plot(f,baseFit(:,i));
                  plot(f,base(:,i));
                  set(gca,'yscale','log');
                  subplot(322); hold on
                  plot(f,10*log10(P(:,i)));
                  plot(f,10*log10(baseFit(:,i)));
                  plot(f,10*log10(base(:,i)));
                  set(gca,'xscale','log'); axis tight;
                  
                  subplot(323); hold on
                  P2 = P(:,i)./baseFit(:,i);
                  plot(f,P2);
                  plot(f,baseSmooth(:,i));
                  subplot(324); hold on
                  plot(f,10*log10(P2));
                  plot(f,10*log10(baseSmooth(:,i)));
                  set(gca,'xscale','log'); axis tight;
                  
                  P3 = Pstan(:,i)./Q(i);
                  subplot(325); hold on
                  plot(f,P3);
                  axis tight; grid on
                  subplot(326); hold on
                  plot(f,P3);
                  set(gca,'xscale','log'); axis tight; grid on
            end
         end
      end
      
      function h = plot(self)
         f = self.rawParams.f;
         Pstan = squeeze(self.detail.values{1});
         if isrow(Pstan)
            Pstan = Pstan';
         end
         alpha = self.baseParams.alpha;
         h = figure;
         plot(self.detail,'log',0,'handle',h,'title',true);
         for i = 1:self.nChannels
            %plot(f,Pstan(:,i));
            subplot(self.nChannels,1,i); hold on;
            p = [.05 .5 .95 .9999];
            for j = 1:numel(p)
               c = gaminv(p(j),alpha(i),1/alpha(i));
               plot([f(2) f(end)],[c c],'-','Color',[1 0 0 0.25]);
               text(f(end),c,sprintf('%1.4f',p(j)));
            end
            %plot([f(2) f(end)],[median(Pstan(:,i)) median(Pstan(:,i))],'-')
            set(gca,'xscale','log');
         end
      end
   end
   
end
