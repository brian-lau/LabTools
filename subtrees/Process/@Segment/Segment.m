% Class for collecting Sampled, Point and EventProcesses with common start
% and end time.
% x Probably should place tStart/tEnd
% x must check for common start and end times!
%   tStart and tEnd are fixed across processes, which could end up with
%   problems of NaN-padding...

% o methods for 
%   o adding processes
%   o 
% 
classdef(CaseInsensitiveProperties, TruncatedProperties) Segment < hgsetget & matlab.mixin.Copyable
   properties
      info@containers.Map % Information about segment
   end
   properties(SetAccess = private)
      processes
      validSync
   end
   properties(SetAccess = private, Dependent = true)
      type
   end
   properties
      labels
      tStart
      tEnd
      window
      offset
   end
   properties(SetAccess = protected, Hidden = true)
      window_  % Original window
      offset_  % Original offset
   end
   properties(SetAccess = protected)
      version = '0.0.0'
   end
   
   methods
      %% Constructor
      function self = Segment(varargin)
         if nargin == 0
            return;
         end

         if (nargin==1) && ~isstruct(varargin{1})
            processes = varargin{1};
            assert(isa(processes,'Process') || iscell(processes),...
               'Segment:Constructor:InputFormat',...
               ['Single inputs be a Process'...
               ', or cell array of Processes.']);
            varargin{1} = 'process';
            varargin{2} = processes;
         end
         
         p = inputParser;
         p.KeepUnmatched= false;
         p.FunctionName = 'Segment constructor';
         p.addParamValue('info',containers.Map('KeyType','char','ValueType','any'));
         p.addParamValue('process',[],@(x) iscell(x) || all(isa(x,'Process')) );
         p.addParamValue('labels',{},@(x) iscell(x) || ischar(x));
         p.addParamValue('window',[],@isnumeric);
         p.addParamValue('offset',0,@isnumeric);
         p.addParamValue('tStart',[],@isnumeric);
         p.addParamValue('tEnd',[],@isnumeric);
         p.parse(varargin{:});
         par = p.Results;

         self.info = par.info;
         
         self.processes = {};
         if ~isempty(par.process)
            if iscell(par.process)
               self.processes = cat(2,self.processes,par.process);
            else
               self.processes = cat(2,self.processes,{par.process});
            end
            if isempty(par.tStart)
               self.tStart = min([cellfun(@(x) x.tStart,self.processes) 0]);
            else
               self.tStart = par.tStart;
            end
            if isempty(par.tEnd)
               self.tEnd = max([max(cellfun(@(x) x.tEnd,self.processes))  self.tStart]);
            else
               self.tEnd = par.tEnd;
            end
                        
            if isempty(par.window)
               self.window = [self.tStart self.tEnd];
            else
               self.window = par.offset;
            end
            if isempty(par.offset)
               self.offset = min(cellfun(@(x) x.offset,self.processes));
            else
               self.offset = par.offset;
            end
         end

         self.labels = p.Results.labels;
         
         % Store original window and offset for resetting
         self.window_ = self.window;
         self.offset_ = self.offset;
      end
      
      function list = get.type(self)
         list = cellfun(@(x) class(x),self.processes,'uni',0);
      end
      
      function set.tStart(self,tStart)
         for i = 1:numel(self.processes)
            self.processes{i}.tStart = tStart;
         end
         self.tStart = tStart;
      end

      function set.tEnd(self,tEnd)
         for i = 1:numel(self.processes)
            self.processes{i}.tEnd = tEnd;
         end
         self.tEnd = tEnd;
      end
      
      function set.offset(self,offset)
         for i = 1:numel(self.processes)
            self.processes{i}.offset = offset;
         end
         self.offset = offset;
      end

      function set.window(self,window)
         for i = 1:numel(self.processes)
            self.processes{i}.window = window;
         end
         self.window = window;
      end
      
      function set.labels(self,labels)
         n = numel(self.processes);
         if isempty(labels)
            self.labels = arrayfun(@(x) ['pid' num2str(x)],1:n,'uni',0);
         elseif iscell(labels)
            assert(all(cellfun(@ischar,labels)),'Segment:labels:InputType',...
               'Labels must be strings');
            assert(numel(labels)==numel(unique(labels)),'Segment:labels:InputType',...
               'Labels must be unique');
            assert(numel(labels)==n,'Segment:labels:InputFormat',...
               '# labels does not match # of processes');
            self.labels = labels;
         elseif (n==1) && ischar(labels)
            self.labels = {labels};
         else
            error('Segment:labels:InputType','Incompatible label type');
         end
      end
      
      self = sync(self,event,varargin)
      proc = extract(self,request,flag)
      self = reset(self)
      
      % add process
      
      %plot
   end
end
