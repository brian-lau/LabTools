% TODO 
%   x should we allow initial process be multiply windowed???
%   o labels can be numeric? 
%   o dimLabels?
% move checkWindows/checkOffset into package? private (faster)?
% set only in constructor
%   - clock, timeUnit
classdef(Abstract) Process < hgsetget & matlab.mixin.Copyable
   properties
      info@containers.Map % Information about process
   end
   properties(SetAccess = protected)
      timeUnit            % Time representation (TODO)
      clock               % Clock info (drift-correction, TODO)
   end
   properties(AbortSet)
      % tStart/tEnd are defined in subclasses since setters are different for each
      %tStart             % Start time of process
      %tEnd               % End time of process
      window              % [min max] time window of interest
   end
   properties
      offset              % Time offset relative to window
                          % Note that window is applied without offset, 
                          % so times can be outside of the window property
      cumulOffset         % Cumulative offset
   end
   properties
      labels              % Label for each element
      quality             % Scalar information for each element
   end
   properties(SetAccess = protected, Transient = true)
      % Window-dependent, but only calculated on window change
      % http://blogs.mathworks.com/loren/2012/03/26/considering-performance-in-object-oriented-matlab-code/
      times = {}          % Event/sample times
      values = {}         % Attribute/value associated with each time
   end
   properties(SetAccess = protected, Dependent = true, Transient = true)
      isValidWindow       % Boolean if window(s) within tStart and tEnd
   end
   properties(SetAccess = protected, Hidden = true)
      times_              % Original event/sample times
      values_             % Original attribute/values
      window_             % Original window
      offset_             % Original offset
      reset_ = false      % reset bit
   end
   properties(SetAccess = protected)
      version = '0.1.0'
   end
   
   methods(Abstract)
      chop(self,shiftToWindow)
      s = sync(self,event,varargin)
      [s,labels] = extract(self,reqLabels)
      %windowfun(self,fun)
      %windowFun(self,fun,nOpt,varargin) % apply applyFunc func?
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
   end
   
   methods(Abstract, Access = protected)
      applyWindow(self);
      applyOffset(self,offset);
   end
   
   methods(Access = protected)
      discardBeforeStart(self)
      discardAfterEnd(self)
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
         applyOffset(self,newOffset);
         self.cumulOffset = self.cumulOffset + newOffset;
      end
      
      % Assignment for object arrays
      self = setWindow(self,window)
      self = setOffset(self,offset)
            
      function set.labels(self,labels)
         n = size(self.values_,2);
         if isempty(labels)
            self.labels = arrayfun(@(x) ['id' num2str(x)],1:n,'uni',0);
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
         n = size(self.values_,2);
         assert(isnumeric(quality),'Process:quality:InputFormat',...
            'Must be numeric');
         
         if isempty(quality)
            quality = ones(1,n);
            self.quality = quality;
         elseif numel(quality)==n
            self.quality = quality(:)';
         elseif numel(quality)==1
            self.quality = repmat(quality,1,n);
         else
            error('bad quality');
         end
      end
      
      function isValidWindow = get.isValidWindow(self)
         isValidWindow = (self.window(:,1)>=self.tStart) & (self.window(:,2)<=self.tEnd);
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
