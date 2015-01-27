% REQUIREMENTS
% R2008b - containers.Maps
% R2010a - containers.Maps constructor to specify key and value type
% R2011a - matlab.mixin.Copyable for copying handle objects
%
% TODO
% move checkWindows/checkOffset into package?
% set only in constructor
%   - clock, timeUnit
% FIXME offset is a misleading name? could imply offset in values...
% TODO 
%   x should we allow initial process be multiply windowed???
%   o labels can be numeric? 
%   o dimLabels?
classdef(CaseInsensitiveProperties, TruncatedProperties) Process < hgsetget & matlab.mixin.Copyable
   properties
      info@containers.Map % Information about process
   end
   properties(SetAccess = protected)
      timeUnit % Time representation (placeholder)
      clock    % Clock info (drift-correction)
   end
   properties(AbortSet)
      % tStart/tEnd are currently in subclasses since setters are different for each
      window   % [min max] time window of interest
      offset   % Offset of event/sample times relative to window
   end
   properties
      labels
      quality
   end
   % Window-dependent, but only calculated on window change
   % http://blogs.mathworks.com/loren/2012/03/26/considering-performance-in-object-oriented-matlab-code/
   properties(SetAccess = protected, Transient = true)
      % Note that any offset is applied *after* windowing, so times can be
      % outside of the windows property
      times    % Event/sample times
      values   % Attribute/value associated with each time
      isValidWindow % Boolean if window(s) lies within tStart and tEnd
   end
   properties(SetAccess = protected, Hidden = true)
      index    % Indices into times/values in window
      times_   % Original event/sample times
      values_  % Original attribute/values
      window_  % Original window
      offset_  % Original offset
   end
   properties(SetAccess = protected)
      version = '0.0.0'
   end
   
   methods(Abstract)
      setInclusiveWindow(self)
      reset(self)
      chop(self,shiftToWindow)
      s = sync(self,event,varargin)
      [s,labels] = extract(self,reqLabels)
      %windowfun(self,fun)
      %windowFun(self,fun,nOpt,varargin) % apply applyFunc func?
      apply(self,fun) % apply applyFunc func?
      %copy?
      %plot
      
      %spectrum
      %spectrogram
      
      % remove % delete by label
      
      % append
      % prepend
      
      % stack? same tStart and tEnd and Fs (for sampled)
      
      % fix = keep current data as original

      % head
      % tail
      
      obj = loadobj(S)
      %toFieldTrip
   end
   
   methods(Abstract, Access = protected)
      applyWindow(self)
      applyOffset(self,undo)
      discardBeforeStart(self);
      discardAfterEnd(self);
   end

   methods
      function set.info(self,info)
         assert(strcmp(info.KeyType,'char'),...
            'Process:info:InputFormat','info keys must be chars.');
         self.info = info;
      end
            
      function set.window(self,window)
         % Set the window property. Does not work for arrays of objects.
         %
         % SEE ALSO
         % setWindow, applyWindow
         self.window = self.checkWindow(window,size(window,1));
         % Reset offset, which always follows window
         self.offset = 'windowIsReset';
         % Expensive, only call when windows are changed (AbortSet=true)
         applyWindow(self);
      end
      
      function set.offset(self,offset)
         % Set the offset property. Does not work for arrays of objects.
         %
         % SEE ALSO
         % setOffset, applyOffset
         if strcmp(offset,'windowIsReset')
            self.offset = zeros(size(self.window,1),1);
         else
            newOffset = self.checkOffset(offset,size(self.window,1));
            % Reset offset, which is always follows window
            applyOffset(self,true);
            self.offset = newOffset;
            % Only call when offsets are changed
            applyOffset(self);
         end
      end
      
      % these handle object array assignment. seems like setters above
      % should call down to these generically when numel(self)>1, and then
      % these can be made private
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
      
      keys = infoKeys(self,flatBool)
      bool = infoHasKey(self,key)
      bool = infoHasValue(self,value,varargin)
      info = copyInfo(self)
   end
   
   methods(Static, Access = protected)
      validWindow = checkWindow(window,n)
      validOffset = checkOffset(offset,n)
   end
end
