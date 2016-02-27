% Regularly sampled process

classdef(CaseInsensitiveProperties) SampledProcess < Process   
   properties(AbortSet, SetObservable)
      tStart              % Start time of process
      tEnd                % End time of process
   end
   properties(SetAccess = protected)
      n = 0                  % # of signals/channels 
   end
   properties
      Fs                  % Sampling frequency
   end
   properties(SetAccess = protected, Hidden)
      Fs_                 % Original sampling frequency
   end
   properties(SetAccess = protected, Dependent)
      dt                  % 1/Fs
      dim                 % Dimensionality of each window
   end
   properties(Dependent, Hidden)
      trailingInd_        % Convenience for expanding non-leading dims
   end
   
   %%
   methods
      %% Constructor
      function self = SampledProcess(varargin)
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
         p.addParameter('Fs',[],@(x) isnumeric(x));
         p.addParameter('values',[],@(x) isnumeric(x) || isa(x,'DataSource'));
         p.addParameter('labels',{},@(x) iscell(x) || ischar(x) || isa(x,'metadata.Label'));
         p.addParameter('quality',[],@isnumeric);
         p.addParameter('window',[],@isnumeric);
         p.addParameter('offset',[],@isnumeric);
         p.addParameter('tStart',0,@isnumeric);
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
            %% "Flatten" matrix, collapsing non-leading dimensions
            dim = size(par.values);
            par.values = reshape(par.values,dim(1),prod(dim(2:end)));
            self.values_ = {par.values};
            self.values = self.values_;
            dim = size(self.values_{1});
         end
         self.times_ = {tvec(par.tStart,1/self.Fs,dim(1))};
         self.times = self.times_;
         
         self.set_n();
         
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
            'SampledProcess:tStart:InputFormat',...
            'tStart must be a numeric scalar.');
         if ~isempty(self.tEnd)
            assert(tStart <= self.tEnd,'SampledProcess:tStart:InputValue',...
                  'tStart must be less than tEnd.');
         end

         if ~self.reset_ && ismatrix(self.values_{1})
            dim = size(self.values_{1});
            [pre,preV] = extendPre(self.tStart,tStart,1/self.Fs_,dim(2:end));
            if ~isempty(pre)
               self.times_ = {[pre ; self.times_{1}]};
               self.values_ = {[preV ; self.values_{1}]};
            end
            if tStart > self.tStart
               self.tStart = tStart;
               self.discardBeforeStart();
            else
               self.tStart = tStart;
            end
         else
            self.tStart = tStart;
         end
      end
      
      function set.tEnd(self,tEnd)
         assert(isscalar(tEnd) && isnumeric(tEnd),...
            'SampledProcess:tEnd:InputFormat',...
            'tEnd must be a numeric scalar.');
         if ~isempty(self.tStart)
            assert(self.tStart <= tEnd,'SampledProcess:tEnd:InputValue',...
                  'tEnd must be greater than tStart.');
         end
         
         if ~self.reset_ && ismatrix(self.values_{1})
            dim = size(self.values_{1});
            [post,postV] = extendPost(self.tEnd,tEnd,1/self.Fs_,dim(2:end));
            if ~isempty(post)
               self.times_ = {[self.times_{1} ; post]};
               self.values_ = {[self.values_{1} ; postV]};
            end
            if tEnd < self.tEnd
               self.tEnd = tEnd;
               self.discardAfterEnd();
            else
               self.tEnd = tEnd;
            end
         else
            self.tEnd = tEnd;
         end         
      end
      
      function set.Fs(self,Fs)
         assert(isscalar(Fs)&&isnumeric(Fs)&&(Fs>0),'SampledProcess:Fs:InputValue',...
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
         elseif strcmp(stack(1).name,'SampledProcess.set.Fs')
            resample(self,Fs);
         end
      end
      
      function dt = get.dt(self)
         dt = 1/self.Fs;
      end
      
      function set_n(self)
         if isempty(self.values)
            self.n = 0;
         else
            self.n = size(self.values{1},2);
         end
      end
      
      function dim = get.dim(self)
         dim = cellfun(@(x) size(x),self.values,'uni',false);
      end
            
      function trailingInd = get.trailingInd_(self)
         dim = size(self.values_{1});
         dim = dim(2:end); % leading dim is always time
         trailingInd = repmat({':'},1,numel(dim));
      end
            
      % In-place transformations
      self = filter(self,b,varargin)
      [self,h,d] = lowpass(self,varargin)
      [self,h,d] = highpass(self,varargin)
      [self,h,d] = bandpass(self,varargin)
      self = detrend(self)
      self = normalize(self,varargin)
      
      % Transformations potentially altering sampling
      self = resample(self,newFs,varargin)
      %decimate
      %interp

      % Output
      [s,labels] = extract(self,reqLabels)
      output = apply(self,fun,nOpt,varargin)
      [out,n,count] = mean(self,varargin)
      obj = psd(self,varargin)
      obj = tfr(self,varargin)
      obj = coh(self,varargin)
      obj = pac(self,varargin)
            
      % Visualization
      h = plot(self,varargin)
      % plotTrajectory

      function S = saveobj(self)
         if ~self.serializeOnSave
            S = self;
         else
            %disp('sampled process saveobj');
            % Converting to bytestream prevents removal of transient/dependent
            % properties, so we have to do this manually
            warning('off','MATLAB:structOnObject');
            S = struct(self);
            S.values = [];
            S.times = [];
            S = getByteStreamFromArray(S);
            warning('on','MATLAB:structOnObject');
         end
      end
   end
   
   methods(Access = protected)
      applySubset(self,subsetOriginal)
      applyWindow(self)
      applyOffset(self,offset)
   end
   
   methods(Static)
      obj = loadobj(S)
   end
end
