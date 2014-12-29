classdef(CaseInsensitiveProperties, TruncatedProperties) PointProcess < Process         
   properties(AbortSet)
      tStart % Start time of process
      tEnd   % End time of process
   end
   % These dependent properties all apply the window property
   properties(SetAccess = private, Dependent = true, Transient = true)
      count  % # of events in window
   end
   
   methods
      %% Constructor
      function self = PointProcess(varargin)
         % Constructor, arguments are taken as name/value pairs
         % info     - Information about point process
         %            containers.Map
         %            cell array, converted to map with generic keys
         % times    - Vector of event times
         % values   - Data corresponding to each event time
         % window   - Defaults to window that includes all event times,
         %            If a smaller window is passed in, event times outside
         %            the window will be DISCARDED.
         
         self = self@Process;
         if nargin == 0
            return;
         end

         if nargin == 1
            times = varargin{1};
            assert(isnumeric(times) || iscell(times),...
               'PointProcess:Constructor:InputFormat',...
                  ['Single inputs must be passed in as array of event times'...
               ', or cell array of arrays of event times.']);
            if isnumeric(times)
               varargin{1} = 'times';
               varargin{2} = times;
            else
               assert(all(cellfun(@isnumeric,times)),...
                  'PointProcess:Constructor:InputFormat',...
                  'Each element of cell array must be a numeric array.');
               varargin{1} = 'times';
               varargin{2} = times;
            end
         end
         
         p = inputParser;
         p.KeepUnmatched= false;
         p.FunctionName = 'PointProcess constructor';
         p.addParamValue('info',containers.Map('KeyType','char','ValueType','any'));
         p.addParamValue('times',{},@(x) isnumeric(x) || iscell(x));
         p.addParamValue('values',{},@(x) isvector(x) || iscell(x) );
         p.addParamValue('labels',{},@(x) iscell(x) || ischar(x));
         p.addParamValue('quality',[],@isnumeric);
         p.addParamValue('window',[],@isnumeric);
         p.addParamValue('offset',0,@isnumeric);
         p.addParamValue('tStart',[],@isnumeric);
         p.addParamValue('tEnd',[],@isnumeric);
         p.parse(varargin{:});
         
         self.info = p.Results.info;
         
         % Create the values cell array
         % FIXME not sorting values yet
         if ~isempty(p.Results.times)
            if isnumeric(p.Results.times)
               [a,b] = unique(p.Results.times(:));
               eventTimes{1} = a;
               tInd{1} = b;
            elseif iscell(p.Results.times)
               [eventTimes,tInd] = cellfun(@(x) unique(x(:)),p.Results.times,'uni',0);
            end
            
            if isempty(p.Results.values)
               values = cellfun(@(x) ones(size(x)),eventTimes,'uni',0);
            else
               if ~iscell(p.Results.values)
                  values = {p.Results.values};
               else
                  values = p.Results.values;
               end
               assert(numel(eventTimes)==numel(values),...
                  'PointProcess:constuctor:InputSize',...
                  '# of ''times'' must equal # of ''values''');
               values = reshape(values,size(eventTimes));
               assert(all(cellfun(@(x,y) numel(x)==numel(y),...
                  values,eventTimes)),'PointProcess:constuctor:InputSize',...
                  '# of ''times'' must equal # of ''values''');
               values = cellfun(@(x) x(:),values,'uni',0);
            end
         else
            if ~isempty(p.Results.values)
               warning('PointProcess:Constructor:InputCount',...
                  'Values ignored without event times');
            end
            return;
         end
         
         % If we have event times
         self.times_ = eventTimes;
         self.values_ = values;
                  
         % Define the start and end times of the process
         if isempty(p.Results.tStart)
            self.tStart = min([cellfun(@min,eventTimes) 0]);
         else
            self.tStart = p.Results.tStart;
         end
         if isempty(p.Results.tEnd)
            self.tEnd = max( max(cellfun(@max,eventTimes)) , self.tStart );
         else
            self.tEnd = p.Results.tEnd;
         end

         % Set the window
         if isempty(p.Results.window)
            self.setInclusiveWindow();
         else
            self.window = self.checkWindow(p.Results.window,size(p.Results.window,1));
         end
         
         % Set the offset
         if isempty(p.Results.offset)
            self.offset = 0;
         else
            self.offset = self.checkOffset(p.Results.offset,size(p.Results.offset,1));
         end         

         % Create labels
         self.labels = p.Results.labels;

         self.quality = p.Results.quality;

         % Store original window and offset for resetting
         self.window_ = self.window;
         self.offset_ = self.offset;
      end % constructor
      
      function set.tStart(self,tStart)
         if ~isempty(self.tEnd)
            if tStart > self.tEnd
               error('PointProcess:tStart:InputValue',...
                  'tStart must be less than tStart.');
            elseif tStart == self.tEnd
               self.tEnd = self.tEnd + eps(self.tEnd);
            end
         end
         if isscalar(tStart) && isnumeric(tStart)
            self.tStart = tStart;
         else
            error('PointProcess:tStart:InputFormat',...
               'tStart must be a numeric scalar.');
         end
         self.discardBeforeStart();
         if ~isempty(self.tEnd)
            self.setInclusiveWindow();
         end
      end
      
      function set.tEnd(self,tEnd)
         if ~isempty(self.tStart)
            if self.tStart > tEnd
               error('PointProcess:tEnd:InputValue',...
                  'tEnd must be greater than tStart.');
            elseif self.tStart == tEnd
               tEnd = tEnd + eps(tEnd);
            end
         end
         if isscalar(tEnd) && isnumeric(tEnd)
            self.tEnd = tEnd;
         else
            error('PointProcess:tEnd:InputFormat',...
               'tEnd must be a numeric scalar.');
         end
         self.discardAfterEnd();
         if ~isempty(self.tStart)
            self.setInclusiveWindow();
         end
      end
      
      function count = get.count(self)
         % # of event times within windows
         if isempty(self.times)
            count = 0;
         else
            count = cellfun(@(x) numel(x),self.times);
         end
      end
      
      self = setInclusiveWindow(self)
      self = reset(self)
      obj = chop(self,shiftToWindow)
      [values,times] = sync(self,event,varargin)
      [s,labels] = extract(self,reqLabels)
      %%
      output = apply(self,fun,nOpt,varargin)
      self = insert(self,times,values,labels)
      self = remove(self,times,labels)
      output = valueFun(self,fun,varargin)
      [bool,times] = hasValue(self,value)
      iei = intervals(self)
      cp = countingProcess(self)
      
      %% Display
      [h,yOffset] = plot(self,varargin)
      [h,yOffset] = raster(self,varargin)
      
      %% Operators
      plus(x,y)
      minus(x,y)
      bool = eq(x,y)
   end
     
   methods(Access = protected)
      applyWindow(self)
      applyOffset(self,undo)
      discardBeforeStart(self)
      discardAfterEnd(self)
   end

   methods(Static)
      obj = loadobj(S)
   end
end

