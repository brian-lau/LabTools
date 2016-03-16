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
% o trimming for edge artifacts
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
      alpha
      permAlgorithm % circshift block trial
      trimEdge
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
   properties%(Dependent)
      permIndex
   end
   
   methods
      function self = CFC(varargin)
         p = inputParser;
         p.KeepUnmatched= false;
         p.FunctionName = 'CFC constructor';
         p.addParameter('input',[],@(x) isa(x,'SampledProcess'));
         p.addParameter('fCentersPhase',(4:4:40),@(x) isnumeric(x));
         p.addParameter('fCentersAmp',(150:10:350),@(x) isnumeric(x));
         p.addParameter('filterBankType','adapt',@ischar);
         p.addParameter('metric','mi',@ischar);
         p.addParameter('nBoot',0,@(x) isnumeric(x) && isscalar(x));
         p.addParameter('permAlgorithm','circshift',@ischar);
         p.addParameter('trimEdge',true,@islogical);
         p.parse(varargin{:});
         par = p.Results;
         
         self.input = par.input;
         self.fCentersPhase = par.fCentersPhase;
         self.fCentersAmp = par.fCentersAmp;
         self.filterBankType = par.filterBankType;
         self.metric = par.metric;
         self.nBoot = par.nBoot;
         self.permAlgorithm = par.permAlgorithm;
         self.trimEdge = par.trimEdge;
      end
      
      function set.nBoot(self,nBoot)
         assert(nBoot>=0,'nBoot must be >= 0');
         self.nBoot = nBoot;
         self.permIndex = self.getPermIndex();
      end
      
      function set.metric(self,metric)
         assert(any(strcmpi(metric,{'direct' 'mi' 'tort' 'mvl' 'canolty'})),'Unknown metric');
         self.metric = lower(metric);
      end
      
      function self = designFilterBank(self)
         [self.hPhase,self.hAmp] = sig.designFilterBankPAC(self.fCentersPhase,...
            self.fCentersAmp,self.input.Fs,'type',self.filterBankType);
         disp('Filter bank computed');
      end
      
      function self = filter(self)
         if isempty(self.hPhase)
            self.designFilterBank();
         end
         
         self.filteredPhase = self.input.filterBank(self.hPhase).hilbert().angle();
         % Store some grouping data {originalLabel fphase}
         for i = 1:numel(self.input)
            count = 1;
            for k = 1:numel(self.fCentersPhase)
               for j = 1:self.input(i).n
                  self.filteredPhase(i).labels(count).grouping{1} = self.input(i).labels(j);
                  self.filteredPhase(i).labels(count).grouping{2} = self.fCentersPhase(k);
                  count = count + 1;
               end
            end
         end
         
         self.filteredAmp = self.input.filterBank(self.hAmp).hilbert();
         self.filteredAmp.abs();
         % Store some grouping data {originalLabel famp fphase}
         if strcmp(self.filterBankType,'adapt')
            loopind = 1:numel(self.fCentersPhase);
         else
            loopind = 1;
         end
         for i = 1:numel(self.input)
            count = 1;
            for k = loopind
               for m = 1:numel(self.fCentersAmp)
                  for j = 1:self.input(i).n
                     self.filteredAmp(i).labels(count).grouping{1} = self.input(i).labels(j);
                     self.filteredAmp(i).labels(count).grouping{2} = self.fCentersAmp(m);
                     self.filteredAmp(i).labels(count).grouping{3} = self.fCentersPhase(k);
                     count = count + 1;
                  end
               end
            end
         end
         
         if self.trimEdge
            Fs = self.filteredPhase.Fs;
            n = max(self.hPhase.impzlength);
            n = max(n,max(self.hAmp(:).impzlength));
            
            window = self.filteredAmp.window;
            self.filteredAmp.window = [window(1)+n/Fs window(2)-n/Fs];
            self.filteredPhase.window = [window(1)+n/Fs window(2)-n/Fs];
         end
         disp('Done filtering');
      end
      
      function bool = isRunnable(self)
         bool = ~isempty(self.input) && ~isempty(self.filteredPhase);
      end
      
      function self = run(self)
         % isRunnable
         self.filter;
         self.comodulogram = estimate(self,1:self.filteredPhase.dim{1}(1));
         
         if self.nBoot > 0 %&& isempty(self.comodulogramBoot)
            if isempty(self.permIndex)
               self.getPermIndex();
            end
            self.comodulogramBoot = zeros(numel(self.fCentersAmp),numel(self.fCentersPhase),self.input.n,self.nBoot);
            for i = 1:self.nBoot
               self.comodulogramBoot(:,:,:,i) = estimate(self,self.permIndex(:,i));
            end
         end
      end
      
      function comodulogram = estimate(self,index)
         uLabels = self.input.labels;
         [phaseValues,labels] = self.filteredPhase.extract;
         phaseValues = phaseValues.values;
         phaseLabels = labels{1};
         [ampValues,labels] = self.filteredAmp.extract;
         ampValues = ampValues.values;
         ampLabels = labels{1};
         
         nfp = numel(self.fCentersPhase);
         nfa = numel(self.fCentersAmp);
         comodulogram = zeros(nfa,nfp,self.input.n);

         for k = 1:self.input.n
            ind = cellfun(@(x) x{1}==uLabels(k),{phaseLabels.grouping});
            phaseValuesk = phaseValues(:,ind);
            ind = cellfun(@(x) x{1}==uLabels(k),{ampLabels.grouping});
            ampValuesk = ampValues(:,ind);
            for i = 1:nfa
               for j = 1:nfp
                  if strcmp(self.filterBankType,'adapt')
                     % Amplitude filters change as a function of phase
                     % frequency, amplitude changes first
                     ampval = ampValuesk(:,(j-1)*nfa+i);
                  else
                     ampval = ampValuesk(:,i);
                  end
                  phaseval = phaseValuesk(:,j);
                  
                  switch self.metric
                     case {'direct' 'ozkurt'}
                        N = length(ampval);
                        z = ampval.*exp(1i*phaseval(index));
                        comodulogram(i,j,k) = (1/sqrt(N)) * abs(mean(z))/sqrt(mean(ampval.^2));
                     case {'mi' 'tort'}
                        comodulogram(i,j,k) = estimateCFC_EAA_Tort2008(phaseval(index),ampval);
                     case {'mvl' 'canolty'}
                        comodulogram(i,j,k) = abs(mean(ampval.*exp(1i*phaseval(index))));
                     case {'glm' 'penny'}
                     case {'glm2' 'kramer'}                        
                  end
               end
            end
         end
      end
      
      function permIndex = getPermIndex(self)
         if isempty(self.permAlgorithm) || self.nBoot == 0
            permIndex = [];
         elseif ~isempty(self.filteredPhase)
            self.rng = rng;
            switch self.permAlgorithm
               case {'circshift'}
                  n = self.filteredPhase.dim{1}(1);
                  shift = unidrnd(n,1,self.nBoot); % random shift
                  permIndex = mod(bsxfun(@plus,(0:n-1)',-shift),n) + 1; % circular shift
            end
         end
      end
      
      function h = plot(self)
         h = figure;
         n = ceil(self.input.n/2);
         for i = 1:self.input.n
            %h = imagesc(self.fCentersPhase,self.fCentersAmp,self.comodulogram(:,:,i));
            %set(gca,'ydir','normal')
            g = subplot(n,2,i,'Parent',h);
            surf(self.fCentersPhase,self.fCentersAmp,self.comodulogram(:,:,i),'edgecolor','none','Parent',g);
            view(g,0,90);
            colorbar
            axis tight;
         end
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
function MI = estimateCFC_EAA_Tort2008(phiLow,aHigh,nBin)
   nBin = 18;
   
   phaseBins = linspace(-pi, pi, nBin + 1);
   aacpd = zeros(numel(phaseBins)-1, 1);
   for kBin = 1:numel(phaseBins)-1
      bIdx = phiLow >= phaseBins(kBin) & phiLow < phaseBins(kBin+1);
      %aacpd(kBin,:) = mean(aHigh(bIdx));
      aacpd(kBin,:) = sum(aHigh(bIdx))/sum(bIdx);
   end
   
   % normalize to make it a distribution
   P = aacpd / sum(aacpd);

   H = -sum(P(P~=0).*log(P(P~=0))); % entropy
   Hmax = -log(1/nBin);
   MI = (Hmax - H)/Hmax;
end
