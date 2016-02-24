% Time-frequency process

classdef(CaseInsensitiveProperties) SpectralProcess < Process   
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
   end
   properties(SetAccess = protected)
      params              
      tBlock              % Duration of each spectral estimate
      tStep               % Duration of step taken for each spectral estimate
      f                   % Frequencies
      band                % like window, but for frequency
   end
   properties(SetAccess = protected, Dependent)
      dim                 % Dimensionality of each window
   end
   properties(Dependent, Hidden)
      trailingInd_        % Convenience for expanding non-leading dims
   end
   
   %%
   methods
      %% Constructor
      function self = SpectralProcess(varargin)
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
         p.FunctionName = 'SpectralProcess constructor';
         p.addParameter('info',containers.Map('KeyType','char','ValueType','any'));
         p.addParameter('values',[],@(x) isnumeric(x) || isa(x,'DataSource'));
         p.addParameter('labels',{},@(x) iscell(x) || ischar(x) || isa(x,'metadata.Label'));
         p.addParameter('quality',[],@isnumeric);
         p.addParameter('window',[],@isnumeric);
         p.addParameter('offset',[],@isnumeric);
         p.addParameter('tStart',0,@isnumeric);
         p.addParameter('tEnd',[],@isnumeric);
         p.addParameter('params',[]);
         p.addParameter('tBlock',[],@isnumeric);
         p.addParameter('tStep',[],@isnumeric);
         p.addParameter('f',[],@isnumeric);
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
            % TODO
         else % in-memory matrix
            %% "Flatten" matrix, collapsing non-leading dimensions
            dim = size(par.values);
            par.values = reshape(par.values,dim(1),dim(2),prod(dim(3:end)));
            self.values_ = {par.values};
            self.values = self.values_;
            dim = size(self.values_{1});
         end
         self.params = par.params;
         self.tBlock = par.tBlock;
         self.tStep = par.tStep;
         self.times_ = {tvec(par.tStart,self.tStep,dim(1))}; 
         self.times = self.times_;
         self.Fs_ = 1/self.tStep;
         self.Fs = self.Fs_;
         
         self.set_n();
      
         % Define the start and end times of the process
         if isa(par.values,'DataSource')
            % TODO
         else
            self.tStart = par.tStart;
         end
         
         self.f = row(par.f);
         
         if isempty(par.tEnd) || isa(par.values,'DataSource')
            % TODO datasource
            self.tEnd = self.times{1}(end) + self.tBlock;
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
            'SpectralProcess:tStart:InputFormat',...
            'tStart must be a numeric scalar.');
         if ~isempty(self.tEnd)
            assert(tStart <= self.tEnd,'SpectralProcess:tStart:InputValue',...
                  'tStart must be less than tEnd.');
         end

         if ~self.reset_ && isnumeric(self.values_{1})
            dim = size(self.values_{1});
            [pre,preV] = extendPre(self.tStart,tStart,self.tStep,dim(2:end));
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
            'SpectralProcess:tEnd:InputFormat',...
            'tEnd must be a numeric scalar.');
         if ~isempty(self.tStart)
            assert(self.tStart <= tEnd,'SpectralProcess:tEnd:InputValue',...
                  'tEnd must be greater than tStart.');
         end
         
         if ~self.reset_ && isnumeric(self.values_{1})
            dim = size(self.values_{1});
            [post,postV] = extendPost(self.tEnd,tEnd,self.tStep,dim(2:end));
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
      
      function set.tBlock(self,tBlock)
         assert(isscalar(tBlock) && isnumeric(tBlock) && (tBlock>0),...
            'SpectralProcess:tBlock:InputFormat',...
            'tBlock must be a numeric scalar > 0.');
         self.tBlock = tBlock;
      end
      
      function set.tStep(self,tStep)
         assert(isscalar(tStep) && isnumeric(tStep) && (tStep>=0),...
            'SpectralProcess:tStep:InputFormat',...
            'tStep must be a numeric scalar >= 0.');
         self.tStep = tStep;
      end
      
      function dt = get.dt(self)
         dt = 1/self.Fs;
      end
      
      function set_n(self)
         if isempty(self.values)
            self.n = 0;
         else
            self.n = size(self.values{1},3);
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
      
      %
      obj = chop(self,shiftToWindow)

      % In-place transformations
      self = normalize(self,varargin)
      
      % Output
      [s,labels] = extract(self,reqLabels)
      output = apply(self,fun,nOpt,varargin)
      [out,n] = mean(self,varargin)
      [out,n] = std(self,varargin)
      
      % Visualization
      h = plot(self,varargin)

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
      applySubset(self)
      applyWindow(self)
      applyOffset(self,offset)
   end
   
   methods(Static)
      obj = loadobj(S)
   end
end
