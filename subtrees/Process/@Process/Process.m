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
   properties(AbortSet)
      window              % [min max] time window of interest
   end
   properties
      offset              % Time offset relative to window
                          % Note that window is applied without offset, 
                          % so times can be outside of the window property
      cumulOffset         % Cumulative offset
      labels              % Label for each element
      quality             % Scalar information for each element
   end
   properties(SetAccess = protected, Transient, GetObservable)
      % Window-dependent, but only calculated on window change
      times = {}          % Event/sample times
      values = {}         % Attribute/value associated with each time
   end
   properties(SetAccess = protected, Dependent, Transient)
      isValidWindow       % Boolean if window(s) within tStart and tEnd
   end
   properties(Abstract, SetAccess = protected, Hidden)
      times_              % Original event/sample times
      values_             % Original attribute/values
   end
   properties(SetAccess = protected, Hidden)
      window_             % Original window
      offset_             % Original offset
      reset_ = false      % reset bit
      running_ = false
   end
   properties(SetAccess = protected)
      lazyLoad = false
      lazyEval = true
      chain = {}
      isLoaded = true
      version = '0.3.0'
   end
   events
      runnable
      loadable
   end
   
   %%
   methods(Abstract)
      chop(self,shiftToWindow)
      s = sync(self,event,varargin)
      [s,labels] = extract(self,reqLabels)
      apply(self,fun) % apply applyFunc func?
      %copy?
      %plot
      
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
   end
   
   methods(Access = protected)
      discardBeforeStart(self)
      discardAfterEnd(self)      
      loadOnDemand(self,varargin)
      evalOnDemand(self,varargin)
      addLink(self,varargin)
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
         % Does not work for arrays of objects. Use setWindow for that.
         %
         % SEE ALSO
         % setWindow, applyWindow
         self.window = checkWindow(window,size(window,1));
         if ~self.isLoaded%self.lazyLoad && ~self.isLoaded
            return;
         end
         if ~self.reset_
            nWindow = size(self.window,1);
            if isempty(self.window) || ((nWindow==1) && (size(self.times,1)==1))
               % For one current & requested window, allow rewindowing current values
               % Reset offset
               applyOffset(self,-self.cumulOffset);
               % Expensive, only call when windows are changed (AbortSet=true)
               applyWindow(self);
               applyOffset(self,self.cumulOffset);
            else
               % Reset the process,
               self.times = self.times_;
               self.values = self.values_;
               
               self.cumulOffset = zeros(nWindow,1);
               applyWindow(self);
               self.offset = self.cumulOffset;
            end
         end
      end
     
      function set.offset(self,offset)
         % Set the offset property
         % Does not work for arrays of objects. Use setOffset for that.
         %
         % SEE ALSO
         % setOffset, applyOffset
         newOffset = checkOffset(offset,size(self.window,1));
         self.offset = newOffset;
         if ~self.isLoaded%self.lazyLoad && ~self.isLoaded
            return;
         end
         applyOffset(self,newOffset);
         self.cumulOffset = self.cumulOffset + newOffset;
      end
      
      % Assignment for object arrays
      self = setWindow(self,window)
      self = setOffset(self,offset)
            
      function set.labels(self,labels)
         dim = size(self.values_{1});
         if numel(dim) > 2
            dim = dim(2:end);
         else
            dim(1) = 1;
         end
         n = prod(dim);
         if isempty(labels)
            self.labels = arrayfun(@(x) ['id' num2str(x)],reshape(1:n,dim),'uni',0);
         elseif iscell(labels)
            assert(all(cellfun(@ischar,labels)),'Process:labels:InputType',...
               'Labels must be strings');
            assert(numel(labels)==numel(unique(labels)),'Process:labels:InputType',...
               'Labels must be unique');
            assert(numel(labels)==n,'Process:labels:InputFormat',...
               '# labels does not match # of signals');
            self.labels = labels;
         elseif (n==1) && ischar(labels)
            self.labels = {labels};
         else
            error('Process:labels:InputType','Incompatible label type');
         end
      end
      
      function set.quality(self,quality)
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
            self.quality = quality;
         elseif all(size(quality)==dim)
            self.quality = quality(:)';
         elseif numel(quality)==1
            self.quality = repmat(quality,dim);
         else
            error('bad quality');
         end
      end
      
      function isValidWindow = get.isValidWindow(self)
         isValidWindow = (self.window(:,1)>=self.tStart) & (self.window(:,2)<=self.tEnd);
      end
      
      function isRunnable(self,~,~)
         if self.lazyLoad
            isLoadable(self);
         end
         disp('checking runnability');
         if isempty(self.chain)
         elseif any(~[self.chain{:,3}]);
            disp('I am runnable');
            notify(self,'runnable');
         end
      end
      
      function isLoadable(self,~,~)
         disp('checking loadability');
         if ~self.isLoaded
            disp('I am loadable');
            notify(self,'loadable');
         end
      end
      
      self = setInclusiveWindow(self)
      self = reset(self)
      self = map(self,func,varargin)
      % Keep current data/transformations as original
      self = fix(self)

      keys = infoKeys(self,flatBool)
      bool = infoHasKey(self,key)
      bool = infoHasValue(self,value,varargin)
      info = copyInfo(self)


      %% Operators
      plus(x,y)
      minus(x,y)
      bool = eq(x,y)
   end
end
