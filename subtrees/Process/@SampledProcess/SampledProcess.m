% Regularly sampled processes

% If multiple processes, currently cannot be multidimensional,
% time = rows

classdef(CaseInsensitiveProperties) SampledProcess < Process   
   properties(AbortSet)
      tStart             % Start time of process
      tEnd               % End time of process
   end
   properties(SetAccess = protected)
      Fs                 % Sampling frequency
   end
   properties(SetAccess = protected, Dependent, Transient)
      dt                 % 1/Fs
      dim                % Dimensionality of each window
   end   
   properties(SetAccess = protected, Hidden)
      Fs_                % Original sampling frequency
   end
   properties(SetAccess = protected, Hidden)
      times_              % Original event/sample times
      values_             % Original attribute/values
   end
   
   %%
   methods
      %% Constructor
      function self = SampledProcess(varargin)
         self = self@Process;
         if nargin == 0
           return;
         end
         
         if mod(nargin,2)==1 && ~isstruct(varargin{1})
            assert(isnumeric(varargin{1}) || isa(varargin{1},'DataSource'),...
               'SampledProcess:Constructor:InputFormat',...
               'Single inputs must be passed in as array of numeric values');
            varargin = {'values' varargin{:}};
         end

         p = inputParser;
         p.KeepUnmatched= false;
         p.FunctionName = 'SampledProcess constructor';
         p.addParameter('info',containers.Map('KeyType','char','ValueType','any'));
         p.addParameter('Fs',[],@(x) isnumeric(x) && isscalar(x));
         p.addParameter('values',[],@(x) isnumeric(x) || isa(x,'DataSource'));
         p.addParameter('labels',{},@(x) iscell(x) || ischar(x));
         p.addParameter('quality',[],@isnumeric);
         p.addParameter('window',[],@isnumeric);
         p.addParameter('offset',[],@isnumeric);
         p.addParameter('tStart',0,@isnumeric);
         p.addParameter('tEnd',[],@isnumeric);
         p.addParameter('lazyLoad',false,@islogical);
         p.addParameter('lazyEval',false,@islogical);
         p.parse(varargin{:});
         
         par = p.Results;
         
         self.info = par.info;
         
         self.lazyEval = par.lazyEval;         
         self.lazyLoad = par.lazyLoad;
         if self.lazyLoad && ~self.lazyEval
            addlistener(self,'values','PreGet',@self.isLoadable);
            addlistener(self,'loadable',@self.loadOnDemand);
            self.isLoaded = false;
         elseif self.lazyEval
            self.running_ = false;
            addlistener(self,'values','PreGet',@self.isRunnable);
            addlistener(self,'runnable',@self.evalOnDemand);
            if self.lazyLoad
               % No listener for loadable since callback for runnable checks
               addlistener(self,'loadable',@self.loadOnDemand);
               self.isLoaded = false;
            else
               self.isLoaded = true;
            end
         end
         
         if isa(par.values,'DataSource')
            assert(isempty(par.Fs),'Cannot specify Fs when using DataSources');
            self.Fs_ = par.values.Fs;
            self.Fs = self.Fs_;
            if self.lazyLoad
               self.values_ = {par.values};
            else
               % Import all data from stream
               ind = repmat({':'},1,numel(par.values.dim));
               self.values_ = {par.values(ind{:})};
               self.values = self.values_;
            end
            dim = par.values.dim;
         else
            if isempty(par.Fs)
               self.Fs_ = 1;
            else
               self.Fs_ = par.Fs;
            end
            self.Fs = self.Fs_;
            if self.lazyLoad
               self.values_ = {par.values};
            else
               self.values_ = {par.values};
               self.values = self.values_;
            end
            dim = size(self.values_{1});
         end
         self.times_ = {self.tvec(par.tStart,self.dt,dim(1))};
         self.times = self.times_;

         % Define the start and end times of the process
         if isa(par.values,'StreamTest')
            self.tStart = par.values.tStart;
         else
            self.tStart = par.tStart;
         end
      
         if isempty(par.tEnd)
            self.tEnd = self.times_{1}(end);
         else
            self.tEnd = par.tEnd;
         end
                  
         % Set the window
         if isempty(par.window)
            self.setInclusiveWindow();
         else
            self.window = par.window;
         end
         
         % Set the offset
         self.cumulOffset = 0;
         if isempty(par.offset)
            self.offset = 0;
         else
            self.offset = par.offset;
         end

         % Create labels
         self.labels = par.labels;
         
         self.quality = par.quality;

         % Store original window and offset for resetting
         self.window_ = self.window;
         self.offset_ = self.offset;
      end % constructor
      
      function set.tStart(self,tStart)
         if ~isempty(self.tEnd)
            assert(tStart < self.tEnd,'SampledProcess:tEnd:InputValue',...
                  'tStart must be less than tEnd.');
         end
         assert(isscalar(tStart) && isnumeric(tStart),...
            'SampledProcess:tStart:InputFormat',...
            'tStart must be a numeric scalar.');
         
         if isa(self.values_{1},'DataSource')
            self.tStart = tStart;
         else
            dim = size(self.values_{1});
            [pre,preV] = self.extendPre(self.tStart,tStart,1/self.Fs_,dim(2:end));
            self.times_ = {[pre ; self.times_{1}]};
            self.values_ = {[preV ; self.values_{1}]};
            self.tStart = tStart;
            self.discardBeforeStart();
         end
%          if ~isempty(self.tEnd)
%             self.setInclusiveWindow();
%          end
      end
      
      function set.tEnd(self,tEnd)
         if ~isempty(self.tStart)
            assert(self.tStart < tEnd,'SampledProcess:tEnd:InputValue',...
                  'tEnd must be greater than tStart.');
         end
         assert(isscalar(tEnd) && isnumeric(tEnd),...
            'SampledProcess:tEnd:InputFormat',...
            'tEnd must be a numeric scalar.');
         
         if isa(self.values_{1},'DataSource')
            self.tEnd = tEnd;
         else
            dim = size(self.values_{1});
            [post,postV] = self.extendPost(self.tEnd,tEnd,1/self.Fs_,dim(2:end));
            self.times_ = {[self.times_{1} ; post]};
            self.values_ = {[self.values_{1} ; postV]};
            self.tEnd = tEnd;
            self.discardAfterEnd();
         end
         
%          if ~isempty(self.tStart)
%             self.setInclusiveWindow();
%          end
      end
      
      function dt = get.dt(self)
         dt = 1/self.Fs;
      end
      
      function dim = get.dim(self)
         dim = cellfun(@(x) size(x),self.values,'uni',false);
      end
      
      % 
      obj = chop(self,shiftToWindow)
      s = sync(self,event,varargin)

      % Transform
      self = filter(self,b,varargin)
      [self,b] = highpass(self,corner,varargin)
      [self,b] = lowpass(self,corner,varargin)
      [self,b] = bandpass(self,corner,varargin)
      self = resample(self,newFs,varargin)
      self = detrend(self)

      % Output
      [s,labels] = extract(self,reqLabels)
      output = apply(self,fun,nOpt,varargin)
      
      % Visualization
      [h,yOffset] = plot(self,varargin)
   end
   
   methods(Access = protected)
      applyWindow(self)
      applyOffset(self,offset)
   end
   
   methods(Static)
      obj = loadobj(S)
      t = tvec(t0,dt,n)
      [pre,preV] = extendPre(tStartOld,tStartNew,dt,dim)
      [post,postV] = extendPost(tEndOld,tEndNew,dt,dim)
   end
end
