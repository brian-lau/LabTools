% Regularly sampled process

classdef(CaseInsensitiveProperties) SampledProcess < Process   
   properties(AbortSet)
      tStart              % Start time of process
      tEnd                % End time of process
   end
   properties(SetAccess = protected, Hidden)
      times_              % Original event/sample times
      values_             % Original attribute/values
   end
   properties
      Fs                  % Sampling frequency
   end
   properties(SetAccess = protected, Dependent, Transient)
      dt                  % 1/Fs
      dim                 % Dimensionality of each window
   end   
   properties(SetAccess = protected, Hidden)
      Fs_                 % Original sampling frequency
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
            varargin = [{'values'} varargin];
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
         p.addParameter('lazyLoad',false,@(x) islogical(x) || isscalar(x));
         p.addParameter('deferredEval',false,@(x) islogical(x) || isscalar(x));
         p.parse(varargin{:});
         par = p.Results;
         
         % Hashmap with process information
         self.info = par.info;
         
         % Listeners and status for lazy loading/evaluation
         self.deferredEval = par.deferredEval;         
         self.lazyLoad = par.lazyLoad;
                  
         % Set sampling frequency and values_/values, times_/times
         if isa(par.values,'DataSource')
            assert(isempty(par.Fs),'SampledProcess:Fs:InputValue',...
               'Fs is specified by DataSource during construction');
            self.Fs_ = par.values.Fs;
            self.Fs = self.Fs_;
            if self.lazyLoad
               self.values_ = {par.values};
            else
               % Import all data from DataSource
               ind = repmat({':'},1,numel(par.values.dim));
               self.values_ = {par.values(ind{:})};
               self.values = self.values_;
            end
            dim = par.values.dim;
         else % in-memory matrix
            if isempty(par.Fs)
               self.Fs_ = 1;
            else
               self.Fs_ = par.Fs;
            end
            self.Fs = self.Fs_;
            self.values_ = {par.values};
            self.values = self.values_;
            dim = size(self.values_{1});
         end
         self.times_ = {self.tvec(par.tStart,self.dt,dim(1))};
         self.times = self.times_;
         
         assert(numel(self.times_{1}) > 1,'SampledProcess:values:InputValue',...
            'Need more than 1 sample to define SampledProcess');

         % Define the start and end times of the process
         if isa(par.values,'DataSource')
            % tStart is taken from DataSource
            self.tStart = par.values.tStart;
         else
            self.tStart = par.tStart;
         end
      
         if isempty(par.tEnd) || isa(par.values,'DataSource')
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
         if isempty(par.offset)
            self.offset = 0;
         else
            self.offset = par.offset;
         end

         % Assign labels/quality
         self.labels = par.labels;         
         self.quality = par.quality;

         % Store original window and offset for resetting
         self.window_ = self.window;
         self.offset_ = self.offset;
         
         % Set running_ bool, which was true (constructor calls not queued)
         if self.deferredEval
            self.running_ = false;
         end
         
         % Don't expose constructor history
         clearQueue(self);
      end % constructor
      
      function set.tStart(self,tStart)
         assert(isscalar(tStart) && isnumeric(tStart),...
            'SampledProcess:tStart:InputFormat',...
            'tStart must be a numeric scalar.');
         if ~isempty(self.tEnd)
            assert(tStart < self.tEnd,'SampledProcess:tStart:InputValue',...
                  'tStart must be less than tEnd.');
         end
         
         if isa(self.values_{1},'DataSource')
            self.tStart = tStart;
         else
            dim = size(self.values_{1});
            [pre,preV] = self.extendPre(self.tStart,tStart,1/self.Fs_,dim(2:end));
            self.times_ = {[pre ; self.times_{1}]};
            self.values_ = {[preV ; self.values_{1}]};
            self.tStart = tStart;
            self.discardBeforeStart();
            
            if ~isempty(self.tEnd)
               self.setInclusiveWindow();
            end
         end
      end
      
      function set.tEnd(self,tEnd)
         assert(isscalar(tEnd) && isnumeric(tEnd),...
            'SampledProcess:tEnd:InputFormat',...
            'tEnd must be a numeric scalar.');
         if ~isempty(self.tStart)
            assert(self.tStart < tEnd,'SampledProcess:tEnd:InputValue',...
                  'tEnd must be greater than tStart.');
         end
         
         if isa(self.values_{1},'DataSource')
            self.tEnd = tEnd;
         else
            dim = size(self.values_{1});
            [post,postV] = self.extendPost(self.tEnd,tEnd,1/self.Fs_,dim(2:end));
            self.times_ = {[self.times_{1} ; post]};
            self.values_ = {[self.values_{1} ; postV]};
            self.tEnd = tEnd;
            self.discardAfterEnd();
            
            if ~isempty(self.tStart)
               self.setInclusiveWindow();
            end
         end         
      end
      
      function set.Fs(self,Fs)
         persistent resampling; % Avoid recursive setting
         
         assert(isscalar(Fs)&&isnumeric(Fs)&&(Fs>0),'SampledProcess:Fs:InputValue',...
            'Fs must be scalar, numeric and > 0');
                  
         %------- Add to function queue ----------
         if ~self.running_ || ~self.deferredEval
            addToQueue(self,Fs);
            if self.deferredEval
               return;
            end
         end
         %----------------------------------------

         if isempty(self.Fs)
            self.Fs = Fs;
            resampling = false;
         elseif (self.Fs ~= Fs) && ~resampling
            resampling = true;
            resample(self,Fs);
         else
            self.Fs = Fs;
            resampling = false;
         end
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

      % In-place transformations
      self = filter(self,b,varargin)
      [self,h,d] = lowpass(self,varargin)
      [self,h,d] = highpass(self,varargin)
      [self,h,d] = bandpass(self,varargin)
      self = detrend(self)
      self = resample(self,newFs,varargin)
      %decimate
      %interp

      % Output
      [s,labels] = extract(self,reqLabels)
      output = apply(self,fun,nOpt,varargin)
      
      % Visualization
      plot(self,varargin)
   end
   
   methods(Access = protected)
      applyWindow(self)
      applyOffset(self,offset)
      
      function l = checkLabels(self,labels)
         dim = size(self.values_{1});
         if numel(dim) > 2
            dim = dim(2:end);
         else
            dim(1) = 1;
         end
         n = prod(dim);
         if isempty(labels)
            l = arrayfun(@(x) ['id' num2str(x)],reshape(1:n,dim),'uni',0);
         elseif iscell(labels)
            assert(all(cellfun(@ischar,labels)),'Process:labels:InputType',...
               'Labels must be strings');
            assert(numel(labels)==numel(unique(labels)),'Process:labels:InputType',...
               'Labels must be unique');
            assert(numel(labels)==n,'Process:labels:InputFormat',...
               '# labels does not match # of signals');
            l = labels;
         elseif (n==1) && ischar(labels)
            l = {labels};
         else
            error('Process:labels:InputType','Incompatible label type');
         end
      end
      
      function q = checkQuality(self,quality)
         dim = size(self.values_{1});
         if numel(dim) > 2
            dim = dim(2:end);
         else
            dim(1) = 1;
         end
         assert(isnumeric(quality),'Process:quality:InputFormat',...
            'Must be numeric');
         
         if isempty(quality)
            quality = ones(dim);
            q = quality;
         elseif all(size(quality)==dim)
            q = quality(:)';
         elseif numel(quality)==1
            q = repmat(quality,dim);
         else
            error('bad quality');
         end
      end
   end
   
   methods(Static)
      obj = loadobj(S)
      t = tvec(t0,dt,n)
      [pre,preV] = extendPre(tStartOld,tStartNew,dt,dim)
      [post,postV] = extendPost(tEndOld,tEndNew,dt,dim)
   end
end
