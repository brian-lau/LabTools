% clear all
% fs = 1000; % sampling frequency
% T = 10000;
% 
% f1 = 20 / fs;
% f2 = 250 / fs;
% e1 = cos(2 * pi * f1 * (1:T) + 0.1 * cumsum(randn(1, T)));
% e2 = exp(-2*e1) .* cos(2 * pi * f2 * (1:T)) / 4;
% x = e1 + e2;
% x = x(:);
% 
% s = SampledProcess(x,'Fs',fs);
% c = CFC;
% c.input = s;
% c.nBoot = 100;
% c.run.plot;

% TODO
% o better shuffling
% o better filter banks
% o get/set for relevant stuff
% o move in all estimators, setters to clear everything
% o kramer glm estimator
% o saving, lots of stuff should be transient, may need info to store names
% o make sure it can work when input is a SampledProcess array
% o multiple channels...

classdef CFC < hgsetget & matlab.mixin.Copyable
   properties
      input
      fCentersPhase
      fCentersAmp
      filterBankType % uniform eeglab adapt, mechanism for parameter passing
      metric
      nBoot
      permAlgorithm % circshift block trial
   end
   properties(SetAccess = protected)
      rng
      hPhase
      hAmp
      filteredPhase
      filteredAmp
      comodulogram
      comodulogramBoot
      phaseDistributions
   end
   properties(Dependent)
      permIndex
   end
   
   methods
      function self = CFC(varargin)
         p = inputParser;
         p.KeepUnmatched= false;
         p.FunctionName = 'CFC constructor';
         p.addParameter('input',[],@(x) isa(x,'SampledProcess'));
         p.addParameter('fCentersPhase',(4:4:40),@(x) isnumeric(x));
         p.addParameter('fCentersAmp',(150:10:300),@(x) isnumeric(x));
         p.addParameter('filterBankType','adapt',@ischar);
         p.addParameter('metric','mi',@ischar);
         p.addParameter('nBoot',0,@(x) isnumeric(x) && isscalar(x));
         p.addParameter('permAlgorithm','circshift',@ischar);
         p.parse(varargin{:});
         par = p.Results;
         
         self.input = par.input;
         self.fCentersPhase = par.fCentersPhase;
         self.fCentersAmp = par.fCentersAmp;
         self.filterBankType = par.filterBankType;
         self.metric = par.metric;
         self.nBoot = par.nBoot;
         self.permAlgorithm = par.permAlgorithm;
      end
      
      function self = designFilterBank(self)
         [self.hPhase,self.hAmp] = sig.designFilterBankPAC(self.fCentersPhase,...
            self.fCentersAmp,self.input.Fs,self.filterBankType);
      end
      
      function self = run(self)
         if isempty(self.hPhase)
            self.designFilterBank();
         end
         if isempty(self.filteredPhase)
            self.filteredPhase = self.input.filterBank(self.hPhase).hilbert().angle();
            self.filteredAmp = self.input.filterBank(self.hAmp).hilbert().abs();
         end
         
         self.comodulogram = estimate(self,1:self.input.dim{1}(1));
         
         if self.nBoot > 0 && isempty(self.comodulogramBoot)
            self.comodulogramBoot = zeros(numel(self.fCentersAmp),numel(self.fCentersPhase),self.nBoot);
            for i = 1:self.nBoot
               self.comodulogramBoot(:,:,i) = estimate(self,self.permIndex(:,i));
            end
         end
      end
      
      function comodulogram = estimate(self,ind)
         phaseValues = self.filteredPhase.values{1};
         ampValues = self.filteredAmp.values{1};
         nfp = numel(self.fCentersPhase);
         nfa = numel(self.fCentersAmp);
         for i = 1:nfa
            for j = 1:nfp
               if strcmp(self.filterBankType,'adapt')
                  ampval = ampValues(:,(j-1)*nfa+i);
               else
                  ampval = ampValues(:,i);
               end
               phaseval = phaseValues(:,j);
               
              % self.comodulogram(i,j) = kramerglm(xl,xh,5,'noplot');
               comodulogram(i,j) = estimateCFC_EAA_Tort2008(phaseval(ind),ampval);
            end
         end         
      end
      
      function permIndex = get.permIndex(self)
         if isempty(self.permAlgorithm) || self.nBoot == 0
            permIndex = [];
         else
            self.rng = rng;
            switch self.permAlgorithm
               case {'circshift'}
                  n = self.input.dim{1}(1);
                  permIndex = repmat((1:n)',1,self.nBoot);
                  for i = 1:self.nBoot
                     permIndex(:,i) = circshift(permIndex(:,i),unidrnd(n));
                  end
            end
         end
      end
      
      function h = plot(self)
         figure;
         h = imagesc(self.fCentersPhase,self.fCentersAmp,self.comodulogram);
         set(gca,'ydir','normal')
      end
   end
   
end

% Functions below are modified from code licensed: 
%
% The MIT License (MIT)
% 
% Copyright (c) 2015 Il Memming Park
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.
function MI = estimateCFC_EAA_Tort2008(phiLow, aHigh, param)
   nBin = 18;
   H = @(P) -sum(P(P~=0).*log(P(P~=0))); % entropy function

   phaseBins = linspace(-pi, pi, nBin + 1);
   phaseBinCenters = (phaseBins(1:end-1) + phaseBins(2:end))/2;
   aacpd = zeros(numel(phaseBins)-1, 1);
   for kBin = 1:numel(phaseBins)-1
      bIdx = phiLow >= phaseBins(kBin) & phiLow < phaseBins(kBin+1);
      aacpd(kBin,:) = mean(aHigh(bIdx));
   end
   
   % normalize to make it a distribution
   aacpd = aacpd / sum(aacpd);

   Hmax = -log(1/nBin);
   MI = (Hmax - H(aacpd))/Hmax;
end
