% TODO;
%  x multichannel
%  o expose baseline parameters
%  x implement irasa, not great
%  o during baseline estimation, consider extending edges to reduce edge effects
%  o remove line noise
%  o spike spectrum
         % TODO handle SampledProcess array
         % TODO handle SampledProcess array
         % TODO detrend option
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
                  baseParams.smoother = 'rlowess';
               end
               if isfield(baseParams,'beta0') && ~isempty(baseParams.beta0)
                  assert(isvector(baseParams.beta0) && (numel(baseParams.beta0)==5),...
                     'Initial conditions have incorrect size for broken-power fit.');
               else
                  baseParams.beta0 = [];
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
               duration = diff(win,1,2);
               % Remove windows that don't match step-size. This ensures
               % that the DOF estimation is correct
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
                     if ~isempty(artifacts(i).values{j}.labels)
                        [~,match] = intersect(labels,artifacts(i).values{j}.labels);
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
            
      function [c,f] = threshold(self,alpha)
         P = self.detail.values{1};
         c = gaminv(1-alpha,self.baseParams.alpha,1/self.baseParams.alpha);
         if nargout == 2
            f = self.detail.f(P>=c);
         end
      end
            
      function self = standardize(self)
         % Rescale detail spectrum to unit variance white noise
         % Approx alpha, this is not correct when window sizes differ
         alpha = self.nSections*mean(self.detail.params.k);
         f = self.raw.f;
         pw = squeeze(self.detail.values{1});
         if self.nChannels == 1
            pw = pw';
         end
         % Match to lower 5% quantile of expected distribution for white noise
         for i = 1:self.nChannels
            Q(i) = gaminv(0.05,alpha(i),1/alpha(i)) ./ (quantile(pw(:,i),0.05));
         end
         if self.nChannels > 1
            self.detail.map(@(x) x.*reshape(repmat(Q,numel(f),1),[1 numel(f) self.nChannels]));
         else
            self.detail.map(@(x) Q*x);
         end
         self.baseParams.alpha = alpha;
         self.baseParams.Q = Q;
      end
      
      function bool = isRunnable(self)
         bool = ~isempty(self.input);
      end

      function run(self)
         import stat.baseline.*

         if ~self.isRunnable
            error('No input signal');
         end
         
         self.section();
         
         % Raw spectrum
         if isfield(self.rawParams,'rubust')
            locFlag = self.rawParams.robust;
         else
            locFlag = 'mean';
         end
         self.rawParams.robust = 'none';
         [out,par] = sig.mtspectrum(self.x_,self.rawParams);
    
         temp = out.P;
         p = zeros(par.nf,self.nChannels);
         for i = 1:self.nChannels
            switch lower(locFlag)
               case {'median'}
                  p(:,i) = median(temp(:,:,i),2);
               case {'huber'}
                  p(:,i) = stat.mlochuber(temp(:,:,i)','k',5)';
               case {'logistic'}
                  p(:,i) = stat.mloclogist(temp(:,:,i)','loc','nanmedian','k',5)';
               otherwise
                  p(:,i) = mean(temp(:,:,i),2);
            end
         end         
         self.rawParams.robust = locFlag;
         
         f = out.f;
         P = zeros([1 size(p)]);
         P(1,:,:) = p; % format for SpectralProcess
         self.raw = SpectralProcess(P,...
            'f',f,'params',par,'tBlock',1,'tStep',1,...
            'labels',self.labels_,'tStart',0,'tEnd',1);
         
         % Estimate base spectrum
         %f = self.raw.f(:);
         switch self.baseParams.method
            case {'broken-power'} % Smoothly broken power-law fit
               p = squeeze(self.raw.values{1});
               if isrow(p)
                  p = p';
               end
               
               % Don't fit DC component TODO : nor nyquist?
               % TODO, implement cutoff frequency or range to restrict fit
               ind = f~=0;
               fnz = f(ind);
               pnz = p(ind,:);
               
               beta = zeros(5,self.nChannels);
               basefit = zeros(size(p));
               basesmooth = ones(size(p));
               % Estimate whitening transformation for each channel
               for i = 1:self.nChannels
                  % Fit smoothly broken power-law using asymmetric error
                  fun = @(b) sum( asymwt(log(smbrokenpl(b,fnz)),log(pnz(:,i))) );
                  
                  if isempty(self.baseParams.beta0)
                     b0 = [1   1  0.5  1   30];   % initial conditions
                  else
                     b0 = self.baseParams.beta0;
                  end
                  lb = [0   -5  0    0   0];      % lower bounds
                  ub = [inf  5  5    5   100];    % upper bounds
                  
                  opts = optimoptions('fmincon','MaxFunEvals',5000,...
                     'Algorithm','sqp','Display','none');
                  [beta(:,i),~,exitflag(i),optout(i)] = fmincon(fun,b0,[],[],[],[],...
                     lb,ub,@smbrokenpl_constraint,opts);
                  
                  % Final fit
                  basefit(:,i) = smbrokenpl(beta(:,i),f);

                  % Smooth residuals
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
               
               % Combine power-law fit with smoother for overall whitening transform
               base = basefit.*basesmooth;
               
               %TODO adjust DC and nyquist?
               
               P = zeros([1 size(base)]);
               P(1,:,:) = base; % format for SpectralProcess
               self.base = SpectralProcess(P,...
                  'f',f,'params',par,'tBlock',1,'tStep',1,...
                  'labels',self.labels_,'tStart',0,'tEnd',1);
               P = zeros([1 size(basefit)]);
               P(1,:,:) = basefit; % format for SpectralProcess
               self.baseFit = SpectralProcess(P,...
                  'f',f,'params',par,'tBlock',1,'tStep',1,...
                  'labels',self.labels_,'tStart',0,'tEnd',1);
               P = zeros([1 size(basesmooth)]);
               P(1,:,:) = basesmooth; % format for SpectralProcess
               self.baseSmooth = SpectralProcess(P,...
                  'f',f,'params',par,'tBlock',1,'tStep',1,...
                  'labels',self.labels_,'tStart',0,'tEnd',1);
               
               % Estimate detail spectrum
               self.detail = copy(self.raw);
               temp = reshape(base,[1 numel(f) self.nChannels]);
               self.detail.map(@(x) x./temp);
               
               self.baseParams.beta0 = b0;
               self.baseParams.beta = beta;
               self.baseParams.exitflag = exitflag;
               self.baseParams.optoutput = optout;
         end
         
         self.standardize();
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
