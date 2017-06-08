% Point process

classdef(CaseInsensitiveProperties) PointProcess < Process         
   properties(AbortSet, SetObservable)
      tStart              % Start time of process
      tEnd                % End time of process
   end
   properties
      Fs                  % Sampling frequency
   end
   properties(SetAccess = protected, Hidden)
      Fs_                 % Original sampling frequency
   end
   properties(SetAccess = protected)
      n = 0               % # of signals/channels 
   end
   properties(SetAccess = protected, Dependent)
      dt                  % 1/Fs
   end
   properties(SetAccess = protected, Dependent)
      count               % # of events in each window
   end
   properties(Dependent, Hidden)
      trailingInd_        % Convenience for expanding non-leading dims
   end
   
   %%
   methods
      %% Constructor
      function self = PointProcess(varargin)
         if nargin == 0
            return;
         end
         if numel(varargin) <= 1
            if isempty(varargin{:})
               return;
            end
         end

         if mod(nargin,2)==1 && ~isstruct(varargin{1})
            assert(isnumeric(varargin{1}) || iscell(varargin{1}),...
               'PointProcess:Constructor:InputFormat',...
                  ['Single inputs must be passed in as array of event times'...
               ', or cell array of arrays of event times.']);
            varargin = [{'times'} varargin];
         end
         
         p = inputParser;
         p.KeepUnmatched = false;
         p.FunctionName = 'PointProcess constructor';
         p.addParameter('info',containers.Map('KeyType','char','ValueType','any'));
         p.addParameter('Fs',1000,@(x) isnumeric(x));
         p.addParameter('times',{},@(x) isnumeric(x) || iscell(x));
         p.addParameter('values',{},@(x) ismatrix(x) || iscell(x) );
         p.addParameter('labels',{},@(x) iscell(x) || ischar(x) || isa(x,'metadata.Label'));
         p.addParameter('quality',[],@isnumeric);
         p.addParameter('window',[],@isnumeric);
         p.addParameter('offset',0,@isnumeric);
         p.addParameter('tStart',[],@isnumeric);
         p.addParameter('tEnd',[],@isnumeric);
         p.addParameter('lazyLoad',false,@(x) islogical(x));
         p.addParameter('deferredEval',false,@(x) islogical(x));
         p.addParameter('history',false,@(x) islogical(x));
         p.parse(varargin{:});
         par = p.Results;
         
         % Hashmap with process information
         self.info = par.info;
         
         % Lazy loading
         if par.lazyLoad
            self.lazyLoad = par.lazyLoad;
         end

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
               for i = 1:numel(times)
                  if isrow(times{i}) && ... % FIXME: this is hacky...
                     ~(isa(self,'EventProcess')&&(numel(times{i})==2))
                     times{i} = times{i}';
                  end
               end
               [eventTimes,tInd] = cellfun(@(x) sortrows(x),times,'uni',0);
            end
            eventTimes = row(eventTimes);
            if isempty(par.values)
               values = cellfun(@(x) ones(size(x,1),1),eventTimes,'uni',0);
            else
               values = row(par.values);
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
                  assert(all(cellfun(@(x,y) numel(x)==size(y,1),values,eventTimes)),...
                     'PointProcess:constuctor:InputSize',...
                     'Cell arrays not matched in dims, # of ''times'' must equal # of ''values''');
                  for i = 1:numel(values)
                     values{i} = reshape(values{i}(tInd{i}),size(eventTimes{i},1),1);
                     %values{i} = vec(values{i}(tInd{i}));
                  end
               end
            end
         end
         
         self.Fs_ = par.Fs;
         self.Fs = self.Fs_;
         eventTimes = cellfun(@(x) roundToSample(x,1/self.Fs),eventTimes,'uni',0);

         % Set times/values
         self.times_ = eventTimes;
         self.values_ = values;
         self.times = self.times_;
         self.values = self.values_;

         self.n = size(eventTimes,2);

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

         % Store original properties for resetting
         self.window_ = self.window;
         self.offset_ = self.offset;
         self.selection_ = true(1,self.n);
         self.labels_ = self.labels;         
         self.quality_ = self.quality;

         if par.history
            self.history = par.history;
         end
         if par.deferredEval
            self.deferredEval = par.deferredEval;
         end
      end % constructor
      
      function set.tStart(self,tStart)
         assert(isscalar(tStart) && isnumeric(tStart),...
            'PointProcess:tStart:InputFormat',...
            'tStart must be a numeric scalar.');
         if ~isempty(self.tEnd)
            assert(tStart <= self.tEnd,'PointProcess:tStart:InputValue',...
                  'tStart must be less than tEnd.');
         end
         
         if ~self.reset_ & (tStart > self.tStart)
            self.tStart = tStart;
            self.discardBeforeStart();
         else
            self.tStart = tStart;
         end
      end
      
      function set.tEnd(self,tEnd)
         assert(isscalar(tEnd) && isnumeric(tEnd),...
            'PointProcess:tEnd:InputFormat',...
            'tEnd must be a numeric scalar.');
         if ~isempty(self.tStart)
            assert(self.tStart <= tEnd,'PointProcess:tEnd:InputValue',...
                  'tEnd must be greater than tStart.');
         end
         if ~self.reset_ & (tEnd < self.tEnd)
            self.tEnd = tEnd;
            self.discardAfterEnd();
         else
            self.tEnd = tEnd;
         end
      end
      
      function set.Fs(self,Fs)
         assert(isscalar(Fs)&&isnumeric(Fs)&&(Fs>0),'PointProcess:Fs:InputValue',...
            'Fs must be scalar, numeric and > 0');
         %------- Add to function queue ----------
         if isQueueable(self)
            addToQueue(self,Fs);
            if self.deferredEval
               return;
            end
         end
         %----------------------------------------

         if self.Fs == Fs
            return;
         elseif isempty(self.Fs)
            self.Fs = Fs;
            return;
         end
         
         stack = dbstack('-completenames');
         if any(strcmp({stack.name},'reset'))
            self.Fs = Fs;
         elseif any(strcmp({stack.name},'resample'))
            self.Fs = Fs;
         elseif strcmp(stack(1).name,'PointProcess.set.Fs')
            resample(self,Fs);
         end
      end
      
      function dt = get.dt(self)
         dt = 1/self.Fs;
      end
      
      function set_n(self)
         self.n = size(self.times,2);
      end
            
      function count = get.count(self)
         % # of event times within windows
         if isempty(self.times)
            count = 0;
         else
            count = cellfun(@(x) size(x,1),self.times);
         end
      end
      
      function trailingInd = get.trailingInd_(self)
         trailingInd = {};
      end
            
      [s,labels] = extract(self,reqLabels)
      
      self = insert(self,times,values,labels)
      self = remove(self,times,labels)

      %%
      output = apply(self,fun,nOpt,varargin)
      sp = smooth(self,varargin)
      output = valueFun(self,fun,varargin)
      [bool,times] = hasValue(self,value)
      iei = intervals(self)
      cp = countingProcess(self)
      
      %% Display
      [h,yOffset] = plot(self,varargin)

      function S = saveobj(self)
         if ~self.serializeOnSave
            S = self;
         else
            %disp('sampled process saveobj');
            % Converting to bytestream prevents removal of transient/dependent
            % properties, so we have to do this manually
            warning('off','MATLAB:structOnObject');
            S = getByteStreamFromArray(struct(self));
            warning('on','MATLAB:structOnObject');
         end
      end
   end
     
   methods(Access = protected)
      applySubset(self,subsetOriginal)
      applyWindow(self)
      applyOffset(self,offset)
      
      times_ = getTimes_(self)
      values_ = getValues_(self)
   end

   methods(Static)
      obj = loadobj(S)
   end
end

