% Time-frequency process

classdef(CaseInsensitiveProperties) SpectralProcess < Process   
   properties(AbortSet)
      tStart              % Start time of process
      tEnd                % End time of process
   end
   % intervals? 
   properties(SetAccess = protected, Hidden)
      times_              % Original event/sample times
      values_             % Original attribute/values
   end
   properties(SetAccess = protected)
      params              
      tBlock              % Duration of each spectral estimate
      tStep               % Duration of step taken for each spectral estimate
      f                   % Frequencies 
   end
   properties(SetAccess = protected, Dependent, Transient)
      dim                 % Dimensionality of each window
   end   
   
   %%
   methods
      %% Constructor
      function self = SpectralProcess(varargin)
         self = self@Process;
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
         p.addParameter('values',[],@(x) isnumeric(x) || isa(x,'DataSource'));
         p.addParameter('labels',{},@(x) iscell(x) || ischar(x));
         p.addParameter('quality',[],@isnumeric);
         p.addParameter('window',[],@isnumeric);
         p.addParameter('offset',[],@isnumeric);
         p.addParameter('tStart',0,@isnumeric);
         p.addParameter('tEnd',[],@isnumeric);
         p.addParameter('params',[]);
         p.addParameter('tBlock',[],@isnumeric);
         p.addParameter('tStep',[],@isnumeric);
         p.addParameter('f',[],@isnumeric);
         p.addParameter('lazyLoad',false,@(x) islogical(x) || isscalar(x));
         p.addParameter('deferredEval',false,@(x) islogical(x) || isscalar(x));
         p.parse(varargin{:});
         par = p.Results;
         
         % Hashmap with process information
         self.info = par.info;
         
         % Lazy loading/evaluation
         self.deferredEval = par.deferredEval;         
         self.lazyLoad = par.lazyLoad;
                  
         % Set sampling frequency and values_/values, times_/times
         if isa(par.values,'DataSource')
            %%%
         else % in-memory matrix
            self.values_ = {par.values};
            self.values = self.values_;
            dim = size(self.values_{1});
         end
         self.params = par.params;
         self.tBlock = par.tBlock;
         self.tStep = par.tStep;
         self.times_ = {self.tvec(par.tStart,self.tStep,dim(1))};
         self.times = self.times_;
         
         % Define the start and end times of the process
         if isa(par.values,'DataSource')
%             % tStart is taken from DataSource
%             self.tStart = par.values.tStart;
         else
            self.tStart = par.tStart;
         end
         
         self.f = vec(par.f);
         
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

         % Store original window and offset for resetting
         self.window_ = self.window;
         self.offset_ = self.offset;
         
         % Set running_ bool, which was true (constructor calls not queued)
         if self.deferredEval
            self.running_ = false;
         end
         
         % Don't expose constructor history
         clearQueue(self);
      end % constructor
      
      function set.tStart(self,tStart)
         assert(isscalar(tStart) && isnumeric(tStart),...
            'SampledProcess:tStart:InputFormat',...
            'tStart must be a numeric scalar.');
         if ~isempty(self.tEnd)
            assert(tStart <= self.tEnd,'SampledProcess:tStart:InputValue',...
                  'tStart must be less than tEnd.');
         end

         if isa(self.values_{1},'DataSource')
            self.tStart = tStart;
         else
            dim = size(self.values_{1});
            [pre,preV] = self.extendPre(self.tStart,tStart,self.tStep,dim(2:end));
            self.times_ = {[pre ; self.times_{1}]};
            self.values_ = {[preV ; self.values_{1}]};
            self.tStart = tStart;
            self.discardBeforeStart();
            
            if ~isempty(self.tEnd)
               self.setInclusiveWindow();
            end
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
         
         if isa(self.values_{1},'DataSource')
            self.tEnd = tEnd;
         else
            dim = size(self.values_{1});
            [post,postV] = self.extendPost(self.tEnd,tEnd,self.tStep,dim(2:end));
            self.times_ = {[self.times_{1} ; post]};
            self.values_ = {[self.values_{1} ; postV]};
            self.tEnd = tEnd;
            self.discardAfterEnd();
            
            if ~isempty(self.tStart)
               self.setInclusiveWindow();
            end
         end         
      end
      
      function set.tBlock(self,tBlock)
         assert(isscalar(tBlock) && isnumeric(tBlock) && (tBlock>0),...
            'SampledProcess:tBlock:InputFormat',...
            'tBlock must be a numeric scalar > 0.');
         self.tBlock = tBlock;
      end
      
      function set.tStep(self,tStep)
         assert(isscalar(tStep) && isnumeric(tStep) && (tStep>=0),...
            'SampledProcess:tStep:InputFormat',...
            'tStep must be a numeric scalar >= 0.');
         self.tStep = tStep;
      end
            
      function dim = get.dim(self)
         dim = cellfun(@(x) size(x),self.values,'uni',false);
      end
            
      %
      obj = chop(self,shiftToWindow)
      s = sync(self,event,varargin)

      % In-place transformations

      % Output
      [s,labels] = extract(self,reqLabels)
      output = apply(self,fun,nOpt,varargin)
      
      % Visualization
      plot(self,varargin)
   end
   
   methods(Access = protected)
      applyWindow(self)
      applyOffset(self,offset)
      
      function l = checkLabels(self,labels)
         dim = size(self.values_{1});
         if numel(dim) > 3
            dim = dim(3:end);
         elseif numel(dim) == 3
            dim = [1 dim(3)];
         else
            dim = [1 1];
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
         if numel(dim) > 3
            dim = dim(3:end);
         elseif numel(dim) == 3
            dim = [1 dim(3)];
         else
            dim = [1 1];
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
      t = tvec(t0,dt,n)
      [pre,preV] = extendPre(tStartOld,tStartNew,dt,dim)
      [post,postV] = extendPost(tEndOld,tEndNew,dt,dim)
   end
end
