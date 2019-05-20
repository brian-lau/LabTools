% setting threshold revalidates bursts, default to keeping everything

classdef BetaBursts < hgsetget & matlab.mixin.Copyable
   properties
      input               % SampledProcess
      instAmpMethod       %
      preprocessParams    %
      postprocessParams   %
      rejectParams        % currently, struct with field 'artifacts'
      pctileThreshold
      minDurThreshold
      threshold           % threshold for detecting burst
   end
   properties(SetAccess = protected)
      instAmp             % instantaneous amplitude
      bTime               % burst times [tStart tEnd]
      bEnvelope           % envelope waveform for each burst (from instAmp)
      bCarrier            % carrier waveform for each burst
      bRaw                % un preprocessed waveform for each burst
   end
   properties(Dependent)
      bMaxAmp             % maximum amplitude of burst (from bEnvelope)
      bDuration
      nChannels           % unique & valid channels
      nExclude            % # of bursts that are not valid
   end
   properties(SetAccess = protected, Hidden)
      reqLabels_
      labels_             % metadata labels for channels
      mask_               % boolean indicating valid bursts
      isPreprocessed_
      isPostprocessed_
      hasInstAmp_
      input_
   end
   properties(SetAccess = immutable)
      version = '0.2.0'   % Version string
   end
   
   methods
      function self = BetaBursts(varargin)
         p = inputParser;
         p.KeepUnmatched= false;
         p.FunctionName = 'BetaBursts constructor';
         p.addParameter('input',[],@(x) isa(x,'SampledProcess') || ischar(x));
         p.addParameter('labels',{});
         p.addParameter('spectrum',[],@(x) isa(x,'Spectrum') || ischar(x));
         p.addParameter('instAmpMethod','hilbert',@ischar);
         p.addParameter('pctileThreshold',75,@(x) isscalar(x) && (x>0) && (x<100));
         p.addParameter('minDurThreshold',0.1,@(x) isscalar(x) && (x>=0));
         p.addParameter('rejectParams',[]);
         p.addParameter('preprocessParams',struct('Fstop1',8,'Fpass1',12,'Fpass2',18,'Fstop2',23,'movmean',20),@isstruct);
         p.addParameter('postprocessParams',struct('baselineRemoval','movmean','baselineWindow',20,'smoothWindow',0.2),@isstruct);
         p.parse(varargin{:});
         par = p.Results;
         
         self.reqLabels_ = par.labels;
         self.input = par.input;
         self.instAmpMethod = par.instAmpMethod;
         self.preprocessParams = par.preprocessParams;
         self.postprocessParams = par.postprocessParams;
         self.pctileThreshold = par.pctileThreshold;
         self.minDurThreshold = par.minDurThreshold;
         self.rejectParams = par.rejectParams;
      end
      
      function bool = isRunnable(self)
         bool = ~isempty(self.input);
      end
      
      function self = set.input(self,input)
         if isempty(input)
            self.input = [];
            self.input_ = [];
            return;
         end
         
         % Reduce to requested labels
         if ~isempty(self.reqLabels_)
            input.subset('labelVal',self.reqLabels_).fix();
         end
         self.input = copy(input);
         self.input_ = copy(input);
         
         % TODO, check labels for array inputs
         self.labels_ = input.labels;
         self.isPreprocessed_ = false;
         self.isPostprocessed_ = false;
         self.hasInstAmp_ = false;
      end
      
      %       function self = set.rejectParams(self,rejectParams)
      %
      %       end
      
      function duration = get.bDuration(self)
         duration = cellfun(@(x) x(:,2)-x(:,1),self.bTime,'uni',0);
      end
      
      function maxAmp = get.bMaxAmp(self)
         maxAmp = cellfun(@(x) cellfun(@max,x),self.bEnvelope,'uni',0);
      end
      
      function nexclude = get.nExclude(self)
         if ~isempty(self.mask_)
            nexclude = cellfun(@(x) sum(~x),self.mask_);
         else
            % TODO
         end
      end
      
      function self = run(self)
         if ~self.isRunnable
            error('No input signal');
         end
         
         self.preprocess();
         self.estimateInstAmp();
         self.postprocess();
         self.detectBursts();
         self.validateBursts();
      end
      
      function self = preprocess(self)
         if ~self.isPreprocessed_
            self.input.bandpass(self.preprocessParams);
            self.input.fix();
            self.isPreprocessed_ = true;
         else
            fprintf('Preprocessing already done\n');
         end
      end
      
      function self = estimateInstAmp(self)
         if ~self.hasInstAmp_
            switch self.instAmpMethod
               case 'hilbert'
                  self.instAmp = copy(self.input);
                  self.instAmp.hilbert().abs().fix();
               case 'teager-kaiser'
                  
               case 'wavelet'
                  
               case 'tinkhauser'
            end
            self.hasInstAmp_ = true;
         else
            fprintf('Instantaneous amplitude already done\n');
         end
      end
      
      function self = postprocess(self)
         if ~self.isPostprocessed_
            
            if isfield(self.postprocessParams,'baselineRemoval')
               Fs = unique([self.instAmp.Fs]);
               assert(isscalar(Fs),'Different sampling frequencies!!');
               k = round(self.postprocessParams.baselineWindow*Fs);
               if k > 1
                  if iseven(k)
                     k = k + 1;
                  end
                  switch self.postprocessParams.baselineRemoval
                     case 'movmean'
                        f = @(x) x - movmean(x,k);
                     case 'movmedian'
                        f = @(x) x - movmedian(x,k);
                     otherwise
                  end
                  %tempPre = extract(self.instAmp);
                  self.instAmp.map(f).fix();
                  %tempPost = extract(self.instAmp);
               end
            end
            
            if isfield(self.postprocessParams,'smoothWindow')
               Fs = unique([self.instAmp.Fs]);
               assert(isscalar(Fs),'Different sampling frequencies!!');
               k = round(self.postprocessParams.smoothWindow*Fs);
               if k > 1
                  if iseven(k)
                     k = k + 1;
                  end
                  f = @(x) movmean(x,k);
                  self.instAmp.map(f).fix();
               end
            end
            
            self.isPostprocessed_ = true;
         else
            fprintf('Postprocessing already done\n');
         end
      end
      
      function detectBursts(self)
         % TODO grab snippets of filtered input & instAmp
         
         % Estimate threshold
         if isempty(self.threshold)
            f = @(x) prctile(x,self.pctileThreshold);
            
            temp = self.instAmp.apply(f);
            if numel(self.instAmp) > 1
               self.threshold = cat(1,temp{:});
            else
               self.threshold = temp;
            end
            
            f = @(x) bsxfun(@(x,y) x>y,x,prctile(x,self.pctileThreshold));
         else
            f = @(x) bsxfun(@(x,y) x>y,x,self.threshold);
         end
         
         % Run detection function
         ev = self.instAmp.detect(f);
         
         % Pull out burst times, envelopes & carriers
         for i = 1:size(ev,1)
            for j = 1:size(ev,2)
               self.instAmp(i).subset(j);           % Isolate channel
               self.instAmp(i).window = ev{i,j};    % Window instAmp
               self.input(i).subset(j);             % Isolate channel
               self.input(i).window = ev{i,j};      % Window filtered
               self.input_(i).subset(j);            % Isolate channel
               self.input_(i).window = ev{i,j};     % Window pre-filtered
               envelope{i,j} = self.instAmp(i).values;
               carrier{i,j} = self.input(i).values;
               raw{i,j} = self.input_(i).values;
               self.instAmp(i).reset();
               self.input(i).reset();
               self.input_(i).reset();
            end
         end
         
         self.bTime = ev;
         self.bEnvelope = envelope;
         self.bCarrier = carrier;
         self.bRaw = raw;
      end
      
      function validateBursts(self)
         if isfield(self.rejectParams,'artifacts')
            labels = self.labels_;
            artifacts = extract(self.rejectParams.artifacts);
            for i = 1:numel(self.input)
               for j = 1:self.input(i).n
                  if numel(artifacts(i).values{1}) > 0
                     for k = 1:numel(artifacts(i).values{1})
                        if any(labels(j)==artifacts(i).values{1}(k).labels)
                           bt = self.bTime{i,j};
                           self.mask_{i,j} = ((bt(:,1) < artifacts(i).values{1}(k).tStart) & (bt(:,2) < artifacts(i).values{1}(k).tStart)) | ...
                              ((bt(:,1) > artifacts(i).values{1}(k).tEnd) & (bt(:,2) > artifacts(i).values{1}(k).tEnd));
                        else
                           self.mask_{i,j} = true(size(self.bTime{i,j},1),1);
                        end
                     end
                  else
                     self.mask_{i,j} = true(size(self.bTime{i,j},1),1);
                  end
                  if self.input(i).quality(j) == 0
                     self.mask_{i,j} = false(size(self.bTime{i,j},1),1);
                  end
                  ind = self.bDuration{i,j} < self.minDurThreshold;
                  self.mask_{i,j}(ind) = false;
               end
            end
         else
            for i = 1:numel(self.input)
               for j = 1:self.input(i).n
                  self.mask_{i,j} = true(size(self.bTime{i,j},1),1);
                  if self.input(i).quality(j) == 0
                     self.mask_{i,j} = false(size(self.bTime{i,j},1),1);
                  end
                  ind = self.bDuration{i,j} < self.minDurThreshold;
                  self.mask_{i,j}(ind) = false;
               end
            end
         end
      end
      
      function self = clean(self)
         self.input = [];
         self.instAmp = [];
      end
            
      function plot(self,c)
         %figure;
         for i = 1:numel(self.labels_)
            subplot(2,3,i); hold on
            dur = cat(1,self.bDuration{:,i});
            amp = cat(1,self.bMaxAmp{:,i});
            scatter(dur,amp,'Markerfacecolor',c,'MarkerEdgeColor',c,'MarkerFaceAlpha',.2,'MarkerEdgeAlpha',.2);
            bad = ~cat(1,self.mask_{:,i});
            plot(dur(bad),amp(bad),'kx');
            title(self.labels_(i).name);
         end
      end
      
      function plotBurst(self,channel,nBurst)
         if nargin < 3
            nBurst = 1;
         end
         if nargin < 2
            channel = 1;
         end
         
         n = 1;
         
         f = figure;
         myhandles = guihandles(f);
         myhandles.channel = channel;
         myhandles.nBurst = nBurst;
         myhandles.n = n;
         
         temp = self.instAmp(n).values{1}(:,channel);
         [N,EDGES] = histcounts(temp,'Normalization','probability');
         
         myhandles.N = N;
         myhandles.EDGES = EDGES;
         guidata(f,myhandles);

         envelope = self.bEnvelope{n,channel}{nBurst,:};
         carrier = self.bCarrier{n,channel}{nBurst,:};
         raw = self.bRaw{n,channel}{nBurst,:};
         bt = self.bTime{n,channel}(nBurst,:);
         thresh = self.threshold{n}(channel);
         t = linspace(bt(1),bt(2),numel(raw));
         
         subplot('Position',[0.1 0.1 .7 .8]);
         hold on;
         plot([t(1) t(end)],[thresh thresh],'k--');
         plot([t(1) t(end)],[0 0],'-','Color',[.9 .9 .9],'LineWidth',.1);
         plot(t,raw,'Color',[.9 .9 .9],'LineWidth',.1);
         plot(t,envelope,'LineWidth',2);
         plot(t,carrier,'LineWidth',2);
         axis tight;
         title([num2str(nBurst) '/' num2str(numel(self.bEnvelope{n,channel})) '/valid=' num2str(self.mask_{n,channel}(nBurst))]);
         ylim = get(gca,'ylim');
         
         subplot('Position',[0.9 0.1 .05 .8]);
         plot(N,EDGES(1:end-1),'k-');
         axis([get(gca,'xlim') ylim]); box off
         
         set(f,'KeyPressFcn',{@self.plotBurstFun,self});
      end
      
      function hist(self,c)
         %figure;
         for i = 1:numel(self.labels_)
            subplot(2,3,i); hold on
            dur = cat(1,self.bDuration{:,i});
            amp = cat(1,self.bMaxAmp{:,i});
            bad = ~cat(1,self.mask_{:,i});
            dur(bad) = [];
            amp(bad) = [];
            histogram(dur,'EdgeColor',c,'Facecolor',c,'EdgeAlpha',0.5,'FaceAlpha',0.2,'Normalization','probability','Binwidth',0.01);
            g = gca;
            if (numel(g.Children) == 2) && isa(g.Children,'matlab.graphics.chart.primitive.Histogram')
               X1 = g.Children(1).Data;
               X2 = g.Children(2).Data;
               [h,p] = kstest2(X1,X2);
               title(['H: ' num2str(h) ', p=' num2str(p)]);
            end
         end
      end
   end
   
   methods(Static)
      function plotBurstFun(src,event,h)
         myhandles = guidata(src);
                        nMax = size(h.bEnvelope,1);

         if strcmp(event.Key,'rightarrow')
            if myhandles.nBurst == numel(h.bEnvelope{myhandles.n,myhandles.channel})
               if myhandles.n < nMax
                  myhandles.n = myhandles.n + 1;
                  nBurst = 1;
               else
                  myhandles.n = 1;
                  nBurst = 1;
               end
            else
               nBurst = myhandles.nBurst + 1;
            end
         elseif strcmp(event.Key,'leftarrow')
            if myhandles.nBurst == 1
               if myhandles.n == 1
                  myhandles.n = nMax;
                  nBurst = numel(h.bEnvelope{nMax,myhandles.channel});
               else
                  myhandles.n = myhandles.n - 1;
                  nBurst = numel(h.bEnvelope{myhandles.n,myhandles.channel});
               end
            else
               nBurst = myhandles.nBurst - 1;
            end
         else
            return;
         end
         n = myhandles.n;
         myhandles.nBurst = nBurst;
         channel = myhandles.channel;
         guidata(src,myhandles);
         
         clf(src);
         subplot('Position',[0.1 0.1 .7 .8]);
         hold on
         envelope = h.bEnvelope{n,channel}{nBurst,:};
         carrier = h.bCarrier{n,channel}{nBurst,:};
         raw = h.bRaw{n,channel}{nBurst,:};
         bt = h.bTime{n,channel}(nBurst,:);
         thresh = h.threshold{n}(channel);
         t = linspace(bt(1),bt(2),numel(raw));
         
         hold on;
         plot([t(1) t(end)],[thresh thresh],'k--');
         plot([t(1) t(end)],[0 0],'-','Color',[.9 .9 .9],'LineWidth',.1);
         plot(t,raw,'Color',[.9 .9 .9],'LineWidth',.1);
         plot(t,envelope,'LineWidth',2);
         plot(t,carrier,'LineWidth',2);
         axis tight;
         title([num2str(nBurst) '/' num2str(numel(h.bEnvelope{n,channel})) '/valid=' num2str(h.mask_{n,channel}(nBurst))]);
         ylim = get(gca,'ylim');
         
         subplot('Position',[0.9 0.1 .05 .8]);
         plot(myhandles.N,myhandles.EDGES(1:end-1),'k-');
         axis([get(gca,'xlim') ylim]); box off;
      end

   end
end