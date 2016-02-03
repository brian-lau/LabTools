% Point process

classdef(CaseInsensitiveProperties) PointProcess < Process         
   properties(AbortSet, SetObservable)
      tStart              % Start time of process
      tEnd                % End time of process
   end
   properties(SetAccess = protected, Hidden)
      times_              % Original event/sample times
      values_             % Original attribute/values
   end
   properties(SetAccess = protected, Dependent)
      count               % # of events in each window
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
            varargin = [{'times'} varargin];
         end
         
         p = inputParser;
         p.KeepUnmatched= false;
         p.FunctionName = 'PointProcess constructor';
         p.addParameter('info',containers.Map('KeyType','char','ValueType','any'));
         p.addParameter('times',{},@(x) isnumeric(x) || iscell(x));
         p.addParameter('values',{},@(x) ismatrix(x) || iscell(x) );
         p.addParameter('labels',{},@(x) iscell(x) || ischar(x) || isa(x,'metadata.Label'));
         p.addParameter('quality',[],@isnumeric);
         p.addParameter('window',[],@isnumeric);
         p.addParameter('offset',0,@isnumeric);
         p.addParameter('tStart',[],@isnumeric);
         p.addParameter('tEnd',[],@isnumeric);
         p.addParameter('lazyLoad',false,@(x) islogical(x) || isscalar(x));
         p.addParameter('deferredEval',false,@(x) islogical(x) || isscalar(x));
         p.addParameter('history',false,@(x) islogical(x) || isscalar(x));
         p.parse(varargin{:});
         par = p.Results;
         
         % Do not store constructor commands
         self.history = false;

         % Hashmap with process information
         self.info = par.info;
         
         % Lazy loading
         self.lazyLoad = par.lazyLoad;

         if isempty(par.times)
            if ~isempty(par.values)
               warning('PointProcess:Constructor:InputCount',...
                  'Values without associated event times were ignored.');
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
                  if isrow(times{i}) && ... % FIXME: this is hacky...
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
               if ismatrix(values) && ~iscell(values) % one PointProcess
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
                  assert(numel(values) == numel(eventTimes),...
                     'PointProcess:constuctor:InputSize',...
                     'Incorrect # of cell arrays, # of ''times'' must equal # of ''values''');
                  assert(all(cellfun(@(x,y) numel(x)==size(y,1),...
                     values,eventTimes)),'PointProcess:constuctor:InputSize',...
                     'Cell arrays not matched in dims, # of ''times'' must equal # of ''values''');
                  for i = 1:numel(values)
                     values{i} = reshape(values{i}(tInd{i}),size(eventTimes{i},1),1);
                  end
               end
            end
         end
         
         % Set times/values
         self.times_ = eventTimes;
         self.values_ = values;
         self.times = self.times_;
         self.values = self.values_;

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
         
         self.history = par.history;
         self.deferredEval = par.deferredEval;         
      end % constructor
      
      function set.tStart(self,tStart)
         if ~isempty(self.tEnd)
            if tStart >= self.tEnd
               error('PointProcess:tStart:InputValue',...
                  'tStart must be less than tEnd.');
           end
         end
         if isscalar(tStart) && isnumeric(tStart)
            self.tStart = tStart;
         else
            error('PointProcess:tStart:InputFormat',...
               'tStart must be a numeric scalar.');
         end
         self.discardBeforeStart();
      end
      
      function set.tEnd(self,tEnd)
         if ~isempty(self.tStart)
            if self.tStart >= tEnd
               error('PointProcess:tEnd:InputValue',...
                  'tEnd must be greater than tStart.');
            end
         end
         if isscalar(tEnd) && isnumeric(tEnd)
            self.tEnd = tEnd;
         else
            error('PointProcess:tEnd:InputFormat',...
               'tEnd must be a numeric scalar.');
         end
         self.discardAfterEnd();
      end
      
      function count = get.count(self)
         % # of event times within windows
         if isempty(self.times)
            count = 0;
         else
            count = cellfun(@(x) size(x,1),self.times);
         end
      end

      function y = roundToProcessResolution(self,x,res)
         if nargin < 3
            % 
            y = x;
         else
            y = round(vec(x)./res).*res;
         end
      end

      obj = chop(self,shiftToWindow)
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
   end
     
   methods(Access = protected)
      applyWindow(self)
      applyOffset(self,offset)
      
      function l = checkLabels(self,labels)
         dim = size(self.times_);
         if numel(dim) > 2
            dim = dim(2:end);
         else
            dim(1) = 1;
         end
         n = prod(dim);
         if isempty(labels)
            l = arrayfun(@(x) ['id' num2str(x)],reshape(1:n,dim),'uni',0);
         elseif iscell(labels)
            assert(numel(labels)==n,'Process:labels:InputFormat',...
               '# labels does not match # of signals');
            l = labels;
         elseif (n==1)
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
   end
end

