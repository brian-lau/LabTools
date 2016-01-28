% Abstract Process class 
classdef(Abstract) Process < hgsetget & matlab.mixin.Copyable
   properties
      info@containers.Map % Information about process
   end
   properties(SetAccess = immutable)
      timeUnit            % Time representation (TODO)
      clock               % Clock info (drift-correction, TODO)
   end
   properties(Abstract)
      tStart              % Start time of process
      tEnd                % End time of process
   end
   properties(Abstract, SetAccess = protected, Hidden)
      times_              % Original event/sample times
      values_             % Original attribute/values
   end
   properties(AbortSet)
      window              % [min max] time window of interest
   end
   properties(Dependent)
      relWindow
   end
   properties
      offset              % Time offset relative to window
      cumulOffset = 0     % Cumulative offset % FIXME PRIVATE?
      labels              % Label for each non-leading dimension
      quality             % Scalar information for each non-leading dimension
   end
   properties(SetAccess = protected, Transient, GetObservable)
      times = {}          % Current event/sample times
      values = {}         % Current attribute/value associated with each time
   end
   properties(SetAccess = protected) %FIXME public?
      lazyLoad = false    % Boolean to defer constructing values from values_
      deferredEval = false% Boolean to defer method evaluations (see addToQueue)
   end
   properties(SetAccess = protected)
      queue = {}          % Method evaluation queue/history
      isLoaded = true     % Boolean indicates whether values constructed
   end
   properties(SetAccess = protected, Dependent, Transient)
      isRunnable = false  % Boolean indicating if queue contains runnable items
      isValidWindow       % Boolean indicating if window(s) within tStart and tEnd
   end
   properties(SetAccess = protected, Hidden)
      window_             % Original window
      offset_             % Original offset
      reset_ = false      % Reset bit
      running_ = true     % Boolean indicating eager evaluation
      queueing_ = true    % Boolean indicating add queueable methods
   end
   properties(SetAccess = protected, Hidden, Transient)
      loadListener_@event.proplistener % lazyLoad listener
      evalListener_@event.listener     % deferredEval listener
   end
   properties(SetAccess = immutable)
      version = '0.4.0'   % Version string
   end
   events
      runImmediately
   end
   
   %%
   methods(Abstract)
      chop(self,shiftToWindow)
      s = sync(self,event,varargin)
      [s,labels] = extract(self,reqLabels)
      apply(self,fun) % apply applyFunc func?
      %copy?
      plot(self)
      
      % remove % delete by label
      
      % append
      % prepend
      
      % disp (overload?)
      % head
      % tail
      
      obj = loadobj(S)
      % saveobj
   end
   
   methods(Abstract, Access = protected)
      applyWindow(self);
      applyOffset(self,offset);
      checkLabels(self)
      checkQuality(self)
   end
   
   methods(Access = protected)
      discardBeforeStart(self)
      discardAfterEnd(self)
      
      addToQueue(self,varargin)
      loadOnDemand(self,varargin)
      evalOnDemand(self,varargin)
      revalOnDemand(self)
   end

   methods
      function set.info(self,info)
         assert(strcmp(info.KeyType,'char'),...
            'Process:info:InputFormat','info keys must be chars.');
         self.info = info;
      end
            
      function set.window(self,window)
         % Set the window property
         % Window applies to times without offset origin.
         % Note that window is applied without offset so times can be 
         % outside of the window property.
         % For setting window of object arrays, use setWindow.
         %
         % SEE ALSO
         % setWindow, applyWindow

         %------- Add to function queue ----------
         if ~self.running_ || ~self.deferredEval
            addToQueue(self,window);
            if self.deferredEval
               return;
            end
         end
         %----------------------------------------
         
         self.window = checkWindow(window,size(window,1));
         if ~self.reset_
            nWindow = size(self.window,1);
            % Rewindow if current and requested # of windows matches
            if isempty(self.window) || (nWindow == size(self.times,1))
               % Reset offset
               applyOffset(self,-self.cumulOffset);
               % Expensive, only call when windows are changed (AbortSet=true)
               applyWindow(self);
               applyOffset(self,self.cumulOffset);
            else % Different windows are ambiguous, start for original
               % Reset the process
               self.times = self.times_;
               self.values = self.values_;
               
               self.cumulOffset = zeros(nWindow,1);
               applyWindow(self);
               self.offset = self.cumulOffset;
            end
         end
      end
      function relWindow = get.relWindow(self)
         relWindow = self.window + self.cumulOffset;
      end
      function set.offset(self,offset)
         % Set the offset property
         % For setting offset of object arrays, use setOffset.
         %
         % SEE ALSO
         % setOffset, applyOffset
         
         %------- Add to function queue ----------
         if ~self.running_ || ~self.deferredEval
            addToQueue(self,offset);
            if self.deferredEval
               return;
            end
         end
         %----------------------------------------

         newOffset = checkOffset(offset,size(self.window,1));
         self.offset = newOffset;
         applyOffset(self,newOffset);
         self.cumulOffset = self.cumulOffset + newOffset;
      end
      
      function set.labels(self,labels)
         %------- Add to function queue ----------
         if ~self.running_ || ~self.deferredEval
            addToQueue(self,labels);
            if self.deferredEval
               return;
            end
         end
         %----------------------------------------
         
         % Wrap abstract method
         labels = checkLabels(self,labels);
         self.labels = labels;
      end
      
      function set.quality(self,quality)
         %------- Add to function queue ----------
         if ~self.running_ || ~self.deferredEval
            addToQueue(self,quality);
            if self.deferredEval
               return;
            end
         end
         %----------------------------------------
         
         % Wrap abstract method
         quality = checkQuality(self,quality);
         self.quality = quality;
      end
      
      function isValidWindow = get.isValidWindow(self)
         isValidWindow = (self.window(:,1)>=self.tStart) & ...
                         (self.window(:,2)<=self.tEnd);
      end
      
      function set.lazyLoad(self,bool)
         assert(isscalar(bool)&&islogical(bool),'err');
         if isempty(self.loadListener_)
            self.loadListener_ = addlistener(self,'values','PreGet',@self.loadOnDemand);
         else
            self.loadListener_.Enabled = bool;
         end
         
         if ~bool
            loadOnDemand(self);
         end
         self.isLoaded = ~bool;
         self.lazyLoad = bool;
      end
      
      function set.deferredEval(self,bool)
         assert(isscalar(bool)&&islogical(bool),'err');
         if isempty(self.evalListener_)
            self.evalListener_ = addlistener(self,'runImmediately',@self.evalOnDemand);
         else
            self.evalListener_.Enabled = bool;
         end
         
         if ~bool
            run(self);
         end
         self.deferredEval = bool;
      end
      
      function set.queue(self,queue)
         assert(iscell(queue),'err');
         % TODO size check?
         % TODO, what if queue exists & is not empty or run? clear or flush
         % or add?
         self.queue = queue;
      end
      
      function isRunnable = get.isRunnable(self)
         isRunnable = false;

         if ~isempty(self.queue) && any(~[self.queue{:,3}])
            isRunnable = true;
         end
      end
      
      function bool = hasLabel(self,label)
         n = numel(self);
         bool = false(n,1);
         for i = 1:n
            bool(i) = any(cellfun(@isequal,self(i).labels,repmat({label},1,numel(self(i).count))));
         end
      end
      
      % Assignment for object arrays
      self = setWindow(self,window)
      self = setOffset(self,offset)
      
      self = clearQueue(self)
      self = disableQueue(self)
      self = enableQueue(self)
      self = run(self,varargin)

      self = setInclusiveWindow(self)
      self = reset(self,n)
      self = undo(self,n)
      self = map(self,func,varargin)
      
      % Keep current data/transformations as original
      self = fix(self)

      keys = infoKeys(self,flatBool)
      bool = infoHasKey(self,key)
      bool = infoHasValue(self,value,varargin)
      info = copyInfo(self)      
      
      function bool = checkVersion(self,req)
         ver = self.version;
         bool = checkVersion(ver,req);
      end
   end
end
