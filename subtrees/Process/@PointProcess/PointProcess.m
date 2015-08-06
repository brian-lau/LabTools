% Point processes

% removed requirement of unique eventTimes (overlapping spikes, etc),
% should default to unique values, possibly check for unique values when
% passed in
%
% uniformValues = true should allow concatonation of values as arrays

classdef(CaseInsensitiveProperties) PointProcess < Process         
   properties(AbortSet)
      tStart             % Start time of process
      tEnd               % End time of process
   end
   properties(SetAccess = protected, Dependent = true, Transient = true)
      count              % # of events in each window
   end
   properties(SetAccess = protected, Hidden = true)
      times_              % Original event/sample times
      values_             % Original attribute/values
   end
   
   %%
   methods
      %% Constructor
      function self = PointProcess(varargin)
         self = self@Process;
         if nargin == 0
            return;
         end

         if mod(nargin,2)==1 && ~isstruct(varargin{1})
            assert(isnumeric(varargin{1}) || iscell(varargin{1}),...
               'PointProcess:Constructor:InputFormat',...
                  ['Single inputs must be passed in as array of event times'...
               ', or cell array of arrays of event times.']);
            varargin = {'times' varargin{:}};
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
         par = p.Results;
         
         self.info = par.info;
         
         if isempty(par.times)
            if ~isempty(par.values)
               warning('PointProcess:Constructor:InputCount',...
                  'Values ignored without event times');
            end
            eventTimes = {};
            values = {};
         else
            times = par.times;
            if isnumeric(times) % one PointProcess
               if isrow(times) && ...
                     ~(isa(self,'EventProcess')&&(numel(times)==2))
                  times = par.times';
               end
               [eventTimes{1},tInd{1}] = sortrows(times);
            else
               for i = 1:numel(times);
                  if isrow(times{i}) && ...
                     ~(isa(self,'EventProcess')&&(numel(times{i})==2))
                     times{i} = times{i}';
                  end
               end
               [eventTimes,tInd] = cellfun(@(x) sortrows(x),times,'uni',0);
            end

            if isempty(par.values)
               values = cellfun(@(x) ones(size(x,1),1),eventTimes,'uni',0);
            else
               values = par.values;
               if iscell(values)
                  assert(numel(values) == numel(eventTimes),...
                     'PointProcess:constuctor:InputSize',...
                     'Incorrect # of cell arrays, # of ''times'' must equal # of ''values''');
                  assert(all(cellfun(@(x,y) numel(x)==size(y,1),...
                     values,eventTimes)),'PointProcess:constuctor:InputSize',...
                     'Cell arrays not matched in dims, # of ''times'' must equal # of ''values''');
                  for i = 1:numel(values)
                     values{i} = reshape(values{i}(tInd{i}),size(eventTimes{i},1),1);
                  end
               elseif ismatrix(values) % one PointProcess
                  if isrow(values) && ...
                        ~(isa(self,'EventProcess')&&(numel(values)==2)) && ...
                        (numel(values) == numel(eventTimes{1}))
                     values = {values(tInd{1})'};
                  elseif (numel(values) == size(eventTimes{1},1))
                     values = {values(tInd{1})};
                  else
                     error('incorrect number of values');
                  end
               else
                  error('PointProcess:tStart:InputType',...
                     'Invalid data type for values');
               end
            end
         end
         
         % If we have event times
         self.times_ = eventTimes;
         self.values_ = values;

         % Define the start and end times of the process
         if isempty(par.tStart)
            self.tStart = min([min(cat(1,eventTimes{:})) 0]);
         else
            self.tStart = par.tStart;
         end
         if isempty(par.tEnd)
            self.tEnd = max([max(cat(1,eventTimes{:}))  self.tStart]);
         else
            self.tEnd = par.tEnd;
         end
         
         %%%% 
         self.times = self.times_;
         self.values = self.values_;
         
         % Set the window
         if isempty(par.window)
            self.setInclusiveWindow();
         else
            self.window = checkWindow(par.window,size(par.window,1));
         end
         
         % Set the offset
         self.cumulOffset = 0;
         if isempty(par.offset)
            self.offset = 0;
         else
            self.offset = checkOffset(par.offset,size(par.offset,1));
         end         

         self.labels = par.labels;
         self.quality = par.quality;

         % Store original window and offset for resetting
         self.window_ = self.window;
         self.offset_ = self.offset;         
      end % constructor
      
      function set.tStart(self,tStart)
         if ~isempty(self.tEnd)
            if tStart > self.tEnd
               error('PointProcess:tStart:InputValue',...
                  'tStart must be less than tEnd.');
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
            count = cellfun(@(x) size(x,1),self.times);
         end
      end
      
      obj = chop(self,shiftToWindow)
      self = sync(self,event,varargin)
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
   end
     
   methods(Access = protected)
      applyWindow(self)
      applyOffset(self,offset)
   end

   methods(Static)
      obj = loadobj(S)
   end
end

