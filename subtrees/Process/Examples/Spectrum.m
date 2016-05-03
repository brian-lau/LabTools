% TODO;
%  o multichannel
%  o expose baseline parameters
%  o implement irasa
%  o during baseline estimation, consider extending edges to reduce edge effects
%  o remove line noise
%  o spike spectrum
classdef Spectrum < hgsetget & matlab.mixin.Copyable
   properties
      input
      whitenParams
      psd
      psdWhite
      psdParams
      verbose
   end
   
   methods
      function self = Spectrum(varargin)
         p = inputParser;
         p.KeepUnmatched= false;
         p.FunctionName = 'Spectrum constructor';
         p.addParameter('input',[],@(x) isa(x,'SampledProcess'));
         p.addParameter('whitenParams',struct('method','power'),@isstruct);
         p.addParameter('psdParams',struct('hbw',0.5),@isstruct);
         p.addParameter('verbose',false,@(x) isscalar(x) && islogical(x));
         p.parse(varargin{:});
         par = p.Results;
         
         self.input = par.input;
         self.whitenParams = par.whitenParams;
         self.psdParams = par.psdParams;
         self.verbose = par.verbose;
      end
      
      function set.input(self,input)
         % TODO VERIFY LABEL MATCHING for SampledProcess array
         % TODO check window sizes
         self.input = input;
         self.psd = [];
         self.psdWhite = [];
      end
      
      function [c,f] = threshold(self,alpha)
         P = self.psdWhite.values{1};
         c = gaminv(1-alpha,self.whitenParams.alpha,1/self.whitenParams.alpha);
         if nargout == 2
            f = self.psdWhite.f(P>=c);
         end
      end
      
      function bool = isRunnable(self)
         bool = ~isempty(self.input);
      end

      function run(self)
         if ~self.isRunnable
            error('No input signal');
         end
         
         % PSD of raw signal
         % TODO handle SampledProcess array
         % TODO detrend option
         self.input.detrend();
         self.psd = self.input.psd(self.psdParams);
         self.psdParams = self.psd.params;
         
         switch self.whitenParams.method
            case {'power'}
               import stat.baseline.*

               f = self.psd.f(:);
               p = squeeze(self.psd.values{1});
               if isrow(p)
                  p = p(:);
               end
               
               % Don't fit DC component TODO : nor nyquist?
               % TODO, implement cutoff frequency or range to restrict fit
               %ind = f~=0;
               ind = f>=1;
               fnz = f(ind);
               pnz = p(ind,:);
               
               b = zeros(5,self.input.n);
               bl = zeros(size(p));
               bls = zeros(size(p));
               % Estimate whitening transformation for each channel
               for i = 1:self.input.n
                  % Fit smoothly broken power-law using asymmetric error
                  fun = @(b) sum( asymwt(log(smbrokenpl(b,fnz)),log(pnz(:,i))) );
                  b0 = [1 1 0.5 1 30];        % initial conditions
                  lb = [0 0 0 0 0];           % lower bounds
                  ub = [inf 10 5 5 f(end)/2]; % upper bounds
                  opts = optimoptions('fmincon','MaxFunEvals',15000);
                  [b(:,i),~,exitflag(i)] = fmincon(fun,b0,[],[],[],[],lb,ub,[],opts);
                  
                  % Smoothly broken power-law fit
                  bl(:,i) = smbrokenpl(b(:,i),f);
                  
                  % Robustly smooth residuals
                  z = p(:,i)./bl(:,i);
                  bls(:,i) = smooth(z,numel(f)/2,'rlowess');
               end
               
               % Combine power-law fit with smoother for overall whitening transform
               bl2 = bl.*bls;
               
               %TODO adjust DC and nyquist?
               
               self.psdWhite = copy(self.psd);
               temp = reshape(bl2,[1 numel(f) self.input.n]);
               self.psdWhite.map(@(x) x./temp);
               
               self.whitenParams.beta = b;
               self.whitenParams.exitflag = exitflag;
               self.whitenParams.baseline1 = bl;
               self.whitenParams.baseline2 = bls;
         end
         
         % Rescale whitened spectrum to unit variance white noise (Thomson refs)
         % Approx alpha (Thomson refs), this is not correct when window
         % sizes are different
         % TODO handle SampledProcess array
         nWindows = numel(self.input.values);
         alpha = nWindows*mean(self.psdWhite.params.k);
         
         pw = squeeze(self.psdWhite.values{1});
         if self.input.n == 1
            pw = pw';
         end
         % Match to lower 5% quantile of expected distribution for white noise
         for i = 1:self.input.n
            Q(i) = gaminv(0.05,alpha,1/alpha) ./ (quantile(pw(:,i),0.05));
         end
         if self.input.n > 1
            self.psdWhite.map(@(x) x.*reshape(repmat(Q,numel(f),1),[1 numel(f) self.input.n]));
         else
            self.psdWhite.map(@(x) Q*x);
         end
         self.whitenParams.alpha = alpha;
         self.whitenParams.Q = Q;
      end
      
      function h = plotDiagnostics(self)
         f = self.psd.f;
         P = squeeze(self.psd.values{1});
         Pstan = squeeze(self.psdWhite.values{1});
         if self.input.n == 1
            P = P';
            Pstan = Pstan';
         end
         Q = self.whitenParams.Q;
         for i = 1:self.input.n
            switch self.whitenParams.method
               case {'power'}
                  bl1 = self.whitenParams.baseline1(:,i);
                  bl2 = self.whitenParams.baseline2(:,i);
                  
                  figure;
                  h = subplot(321); hold on
                  plot(f,P(:,i));
                  plot(f,bl1);
                  plot(f,bl1.*bl2);
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
         f = self.psdParams.f;
         Pstan = squeeze(self.psdWhite.values{1});
         if isrow(Pstan)
            Pstan = Pstan';
         end
         alpha = self.whitenParams.alpha;
         for i = 1:self.input.n
            h = figure;
            hold on;
            %plot(self.psdWhite,'log',0,'handle',h);
            plot(f,Pstan(:,i));
            p = [.05 .5 .95 .99 .999 .9999];
            for j = 1:numel(p)
               c = gaminv(p(j),alpha,1/alpha);
               plot([f(2) f(end)],[c c],'-','Color',[1 0 0 0.25]);
               text(f(end),c,sprintf('%1.4f',p(j)));
            end
            plot([f(2) f(end)],[median(Pstan(:,i)) median(Pstan(:,i))],'-')
            %set(gca,'xscale','log');
         end
      end
   end
   
end
