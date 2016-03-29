classdef Spectrum < hgsetget & matlab.mixin.Copyable
   properties
      input
      resid
      prewhitenParams
      psd
      psdWhite
      psdParams
      %alpha
   end
   
   methods
      function self = Spectrum(varargin)
         p = inputParser;
         p.KeepUnmatched= false;
         p.FunctionName = 'Spectrum constructor';
         p.addParameter('input',[],@(x) isa(x,'SampledProcess'));
         p.addParameter('prewhitenParams',[],@isstruct);
         p.addParameter('psdParams',[],@isstruct);
         p.parse(varargin{:});
         par = p.Results;
         
         self.input = par.input;
         if isempty(par.prewhitenParams)
            self.prewhitenParams = struct('method','ar+');
         end
         if isempty(par.psdParams)
            self.psdParams = struct('hbw',0.5);
         end
      end
      
      function [c,f] = threshold(self,alpha)
         P = self.psdWhite.values{1};
         c = gaminv(1-alpha,self.prewhitenParams.alpha,1/self.prewhitenParams.alpha);
         if nargout == 2
            f = self.psdWhite.f(P>=c);
         end
      end
      
      function bool = isRunnable(self)
         bool = ~isempty(self.input);
      end

      function run(self)
         
         switch self.prewhitenParams.method
            case {'ar' 'ar+'}
               fitARModel(self);
               
               % PSD of raw signal
               self.psd = self.input.psd(self.psdParams);
               % PSD of AR(1) whitened signal
               self.psdWhite = self.resid.psd(self.psdParams);
               
               % Put in loop for multiple channels
               bl = stat.baseline.arpls(self.psdWhite.values{1}',5e6);
               self.psdWhite.map(@(x) x - bl' + mean(bl));
               
               nWindows = numel(self.input.values);
               alpha = nWindows*mean(self.psdWhite.params.k);
               Q = gaminv(0.05,alpha,1/alpha) ./ ...
                  (quantile(self.psdWhite.values{1},0.05));
               
               self.psdWhite.map(@(x) Q*x);
               
               self.prewhitenParams.baseline = bl;
               self.prewhitenParams.alpha = alpha;
               self.prewhitenParams.Q = Q;
            case 'fractal'
               
         end

      end

      function fitARModel(self)
         self.input.detrend();
         % TODO VERIFY LABEL MATCHING (SHOULD BE DONE ON INPUT)
         [values,labels] = extract(self.input);
         if iscell(values.values)
            nWin = numel(values.values);
            values.values = values.values';
            for i = 1:nWin
               values.values{2,i} = NaN;
            end
            x = cat(1,values.values{:});
         else
            nWin = 1;
            x = values.values;
         end
         
         % Fit MVAR for all data
         [what,Ahat,sigma] = arfit2(x,1,1);
         
         %res = zeros(size(self.input.values{1}));
         for i = 1:nWin
            if iscell(values.values)
               [~,res{i}] = arres(what,Ahat,values.values{1,i},2);
            else
               [~,res{i}] = arres(what,Ahat,values.values,2);
            end
         end
         self.resid = copy(self.input);
         self.resid.map(@(x,y) [zeros(1,self.input.n);y],'B',res');

         self.prewhitenParams.Ahat = Ahat;
         self.prewhitenParams.what = what;
         self.prewhitenParams.sigma = sigma;
      end
      
      function h = plotDiagnostics(self)
         f = self.psd.f;
         P = self.psd.values{1};
         Pstan = self.psdWhite.values{1};
         bl = self.prewhitenParams.baseline;
         Q = self.prewhitenParams.Q;
         Par1 = stat.arspectrum(self.prewhitenParams.Ahat,...
            self.prewhitenParams.sigma,self.input.Fs,f);
         
         figure;
         h = subplot(321); hold on
         plot(f,P);
         plot(f,Par1);
         subplot(322); hold on
         plot(f,10*log10(P));
         plot(f,10*log10(Par1));
         set(gca,'xscale','log'); axis tight;
         
         subplot(323); hold on
         Par1res = Pstan./Q + bl' - mean(bl);
         plot(f,Par1res);
         plot(f,bl);
         subplot(324); hold on
         plot(f,10*log10(Par1res));
         plot(f,10*log10(bl));
         set(gca,'xscale','log'); axis tight;
         
         Par1resbl = Pstan./Q;
         subplot(325); hold on
         plot(f,Par1resbl);
         axis tight; grid on
         subplot(326); hold on
         plot(f,Par1resbl);
         set(gca,'xscale','log'); axis tight; grid on
      end
      
      function h = plot(self)
         f = self.psdParams.f;
         h = figure;
         hold on;
         plot(self.psdWhite,'log',0,'handle',h);
         p = [.05 .5 .95 .99 .999 .9999];
         alpha = self.prewhitenParams.alpha;
         for i = 1:numel(p)
            c = gaminv(p(i),alpha,1/alpha);
            plot([f(2) f(end)],[c c],'-','Color',[1 0 0 0.25]);
            text(f(end),c,sprintf('%1.4f',p(i)));
         end
         Pstan = self.psdWhite.values{1};
         plot([f(1) f(end)],[median(Pstan) median(Pstan)],'-')
      end
   end
   
end
