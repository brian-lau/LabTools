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
      raw   % direct multitaper spectral estimate
      rawParams % 
      base  % estimate of base spectrum
      baseParams
      detail % estimate of detail spectrum (whitened & standardized)
      
      verbose
   end
   
   methods
      function self = Spectrum(varargin)
         p = inputParser;
         p.KeepUnmatched= false;
         p.FunctionName = 'Spectrum constructor';
         p.addParameter('input',[],@(x) isa(x,'SampledProcess'));
         p.addParameter('baseParams',struct('method','broken-power'),@isstruct);
         p.addParameter('rawParams',struct('hbw',0.5),@isstruct);
         p.addParameter('verbose',false,@(x) isscalar(x) && islogical(x));
         p.parse(varargin{:});
         par = p.Results;
         
         self.input = par.input;
         self.baseParams = par.baseParams;
         self.rawParams = par.rawParams;
         self.verbose = par.verbose;
      end
      
      function set.input(self,input)
         % TODO VERIFY LABEL MATCHING for SampledProcess array
         % TODO check window sizes
         self.input = input;
         % Remove any previous estimates
         self.raw = [];
         self.base = [];
      end
      
      function set.baseParams(self,baseParams)
         if isfield(baseParams,'smoother')
            
         else
            baseParams.smoother = 'rlowess';
         end
         if isfield(baseParams,'beta0')
            
         else
            baseParams.beta0 = [];
         end
         self.baseParams = baseParams;
      end
      
      function [c,f] = threshold(self,alpha)
         P = self.detail.values{1};
         c = gaminv(1-alpha,self.baseParams.alpha,1/self.baseParams.alpha);
         if nargout == 2
            f = self.detail.f(P>=c);
         end
      end
      
      function bool = isRunnable(self)
         bool = ~isempty(self.input);
      end

      function run(self)
         import stat.baseline.*

         if ~self.isRunnable
            error('No input signal');
         end
         
         % Raw spectrum
         self.raw = self.input.psd(self.rawParams);
         
         % Estimate base spectrum
         switch self.baseParams.method
            case {'broken-power'} % Smoothly broken power-law fit
               f = self.raw.f(:);
               p = squeeze(self.raw.values{1});
               if isrow(p)
                  p = p(:);
               end
               
               % Don't fit DC component TODO : nor nyquist?
               % TODO, implement cutoff frequency or range to restrict fit
               ind = f~=0;
               fnz = f(ind);
               pnz = p(ind,:);
               
               beta = zeros(5,self.input.n);
               basefit = zeros(size(p));
               basesmooth = ones(size(p));
               % Estimate whitening transformation for each channel
               for i = 1:self.input.n
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
               
               % Estimate detail spectrum
               self.detail = copy(self.raw);
               temp = reshape(base,[1 numel(f) self.input.n]);
               self.detail.map(@(x) x./temp);
               
               self.baseParams.beta = beta;
               self.baseParams.exitflag = exitflag;
               self.baseParams.optoutput = optout;
               self.baseParams.basefit = basefit;
               self.baseParams.basesmooth = basesmooth;
         end
         
         % Rescale detail spectrum to unit variance white noise
         % Approx alpha, this is not correct when window sizes differ
         nSections = numel(self.input.values);
         alpha = nSections*mean(self.detail.params.k);

         pw = squeeze(self.detail.values{1});
         if self.input.n == 1
            pw = pw';
         end
         % Match to lower 5% quantile of expected distribution for white noise
         for i = 1:self.input.n
            Q(i) = gaminv(0.05,alpha,1/alpha) ./ (quantile(pw(:,i),0.05));
         end
         if self.input.n > 1
            self.detail.map(@(x) x.*reshape(repmat(Q,numel(f),1),[1 numel(f) self.input.n]));
         else
            self.detail.map(@(x) Q*x);
         end
         self.baseParams.alpha = alpha;
         self.baseParams.Q = Q;
      end
      
      function h = plotDiagnostics(self)
         f = self.raw.f;
         P = squeeze(self.raw.values{1});
         Pstan = squeeze(self.detail.values{1});
         if self.input.n == 1
            P = P';
            Pstan = Pstan';
         end
         Q = self.baseParams.Q;
         for i = 1:self.input.n
            switch self.baseParams.method
               case {'broken-power'}
                  bl1 = self.baseParams.basefit(:,i);
                  bl2 = self.baseParams.basesmooth(:,i);
                  
                  figure;
                  h = subplot(321); hold on
                  plot(f,P(:,i));
                  plot(f,bl1);
                  plot(f,bl1.*bl2);
                  set(gca,'yscale','log');
                  subplot(322); hold on
                  plot(f,10*log10(P(:,i)));
                  plot(f,10*log10(bl1));
                  plot(f,10*log10(bl1.*bl2));
                  set(gca,'xscale','log'); axis tight;
                  
                  subplot(323); hold on
                  P2 = P(:,i)./bl1;
                  plot(f,P2);
                  plot(f,bl2);
                  subplot(324); hold on
                  plot(f,10*log10(P2));
                  plot(f,10*log10(bl2));
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
         for i = 1:self.input.n
            %plot(f,Pstan(:,i));
               subplot(self.input.n,1,i); hold on;
            p = [.05 .5 .95 .9999];
            for j = 1:numel(p)
               c = gaminv(p(j),alpha,1/alpha);
               plot([f(2) f(end)],[c c],'-','Color',[1 0 0 0.25]);
               text(f(end),c,sprintf('%1.4f',p(j)));
            end
            %plot([f(2) f(end)],[median(Pstan(:,i)) median(Pstan(:,i))],'-')
            set(gca,'xscale','log');
         end
      end
   end
   
end
