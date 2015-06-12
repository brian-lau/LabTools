% Regularly sampled processes
% If multiple processes, currently cannot be multidimensional,
% time = rows

classdef(CaseInsensitiveProperties, TruncatedProperties) SampledProcess < Process   
   properties(AbortSet)%(AbortSet, Access=?Segment)
      tStart % Start time of process
      tEnd   % End time of process
   end
   properties(SetAccess = protected)
      Fs % Sampling frequency
   end
   properties(SetAccess = protected, Dependent = true, Transient = true)
      dim
      dt
   end   
   properties(SetAccess = protected, Hidden = true)
      Fs_ % Original sampling frequency
   end
   
   methods
      %% Constructor
      function self = SampledProcess(varargin)
         self = self@Process;
         if nargin == 0
           return;
         end
         
         if nargin == 1
            values = varargin{1};
            assert(isnumeric(values),...
               'SampledProcess:Constructor:InputFormat',...
               'Single inputs must be passed in as array of numeric values');
            if isnumeric(values)
               varargin{1} = 'values';
               varargin{2} = values;
            end
         end

         p = inputParser;
         p.KeepUnmatched= false;
         p.FunctionName = 'SampledProcess constructor';
         p.addParamValue('info',containers.Map('KeyType','char','ValueType','any'));
         p.addParamValue('Fs',1);
         p.addParamValue('values',[],@ismatrix );
         p.addParamValue('labels',{},@(x) iscell(x) || ischar(x));
         p.addParamValue('quality',[],@isnumeric);
         p.addParamValue('window',[],@isnumeric);
         p.addParamValue('offset',[],@isnumeric);
         p.addParamValue('tStart',0,@isnumeric);
         p.addParamValue('tEnd',[],@isnumeric);
         p.parse(varargin{:});
         
         self.info = p.Results.info;
         
         % Create values array
         if isvector(p.Results.values)
            self.values_ = p.Results.values(:);
         else
            % Assume leading dimension is time
            % FIXME, should probably force to 2D? Actually, maybe not,
            % allow user to preserve dimensions after leading
            self.values_ = p.Results.values;
         end
         self.Fs_ = p.Results.Fs;
         self.Fs = self.Fs_;
         dt = 1/self.Fs_;
         self.times_ = self.tvec(p.Results.tStart,dt,(size(self.values_,1)));
         
         % Define the start and end times of the process
         self.tStart = p.Results.tStart;
         if isempty(p.Results.tEnd)
            self.tEnd = self.times_(end);
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
               error('SampledProcess:tStart:InputValue',...
                  'tStart must be less than tEnd.');
            elseif tStart == self.tEnd
               self.tEnd = self.tEnd + eps(self.tEnd);
            end
         end
         if isscalar(tStart) && isnumeric(tStart)
            pre = self.extendPre(self.tStart,tStart,1/self.Fs_);
            preV = nan(size(pre,1),size(self.values_,2));
            self.times_ = [pre ; self.times_];
            self.values_ = [preV ; self.values_];
            self.tStart = tStart;
         else
            error('SampledProcess:tStart:InputFormat',...
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
               error('SampledProcess:tEnd:InputValue',...
                  'tEnd must be greater than tStart.');
            elseif self.tStart == tEnd
               tEnd = tEnd + eps(tEnd);
            end
         end
         if isscalar(tEnd) && isnumeric(tEnd)
            post = self.extendPost(self.tEnd,tEnd,1/self.Fs_);
            postV = nan(size(post,1),size(self.values_,2));
            self.times_ = [self.times_ ; post];
            self.values_ = [self.values_ ; postV];
            self.tEnd = tEnd;
         else
            error('SampledProcess:tEnd:InputFormat',...
               'tEnd must be a numeric scalar.');
         end
         self.discardAfterEnd();
         if ~isempty(self.tStart)
            self.setInclusiveWindow();
         end
      end
      
      function dt = get.dt(self)
         dt = 1/self.Fs;
      end
      
      function dim = get.dim(self)
         dim = cellfun(@(x) size(x),self.values,'uni',false);
      end
      
      % 
      self = setInclusiveWindow(self)
      self = reset(self)
      obj = chop(self,shiftToWindow)
      s = sync(self,event,varargin)

      % Transform
      self = filter(self,b,varargin)
      [self,b] = highpass(self,corner,varargin)
      [self,b] = lowpass(self,corner,varargin)
      [self,b] = bandpass(self,corner,varargin)
      self = resample(self,newFs,varargin)
      %self = smooth(self)
      self = detrend(self)
      self = map(self,func,varargin)

      % Output
      [s,labels] = extract(self,reqLabels)
      output = apply(self,fun,nOpt,varargin)

      dat = convert2Fieldtrip(self)
      
      % Visualization
      plot(self,varargin)
   end
   
   methods(Access = protected)
      applyWindow(self)
      applyOffset(self,undo)
      discardBeforeStart(self)
      discardAfterEnd(self)
   end
   
   methods(Static)
      obj = loadobj(S)
      t = tvec(t0,dt,n)
      pre = extendPre(tStartOld,tStartNew,dt)
      post = extendPost(tEndOld,tEndNew,dt)
   end
end
