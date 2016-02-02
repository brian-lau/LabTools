% Class for collecting Processes with common:
%    tStart
%    tEnd
%    window
%    offset

classdef(CaseInsensitiveProperties, TruncatedProperties) Segment < hgsetget & matlab.mixin.Copyable
   properties
      info@containers.Map % Information about segment
   end
   properties(SetAccess = private)
      processes
   end
   properties(Dependent = true)
      type
   end
   properties
      labels
      tStart
      tEnd
      window
      offset
      
      coordinateProcesses
   end
   properties(SetAccess = private)
      validSync
   end
   % validSegment? all processes have same parent segment?
   properties(Dependent = true)
      sampledProcess
      pointProcess
      eventProcess
      spectralProcess
   end
   properties
      
      blocks%@Block    %
      listeners_
   end
   properties(SetAccess = protected)
      version = '0.2.0'
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
         p.addParameter('info',containers.Map('KeyType','char','ValueType','any'));
         p.addParameter('process',[],@(x) iscell(x) || all(isa(x,'Process')) );
         p.addParameter('labels',{},@(x) iscell(x) || ischar(x));
         p.addParameter('tStart',[],@isnumeric);
         p.addParameter('tEnd',[],@isnumeric);
         p.addParameter('window',[],@isnumeric);
         p.addParameter('offset',0,@isnumeric);
         p.addParameter('coordinateProcesses',false,@islogical);
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
            
            % Remove existing Segment reference to all child processes
            cellfun(@(x) set(x,'segment',[]),self.processes,'uni',0);
            
            if isempty(par.tStart)
               tStart = unique(cellfun(@(x) x.tStart,self.processes));
               if numel(tStart) > 1
                  error('Segment:Constructor:InputFormat',...
                     'Start times for all processes must be equal');
               end
            else
               self.tStart = par.tStart;
            end
            if isempty(par.tEnd)
               tEnd = unique(cellfun(@(x) x.tEnd,self.processes));
               if numel(tEnd) > 1
                  error('Segment:Constructor:InputFormat',...
                     'End times for all processes must be equal');
               end
            else
               self.tEnd = par.tEnd;
            end
                        
            if isempty(par.window)
               window = cell.uniqueRows(cellfun(@(x) x.window,self.processes','uni',0));
               if numel(window) > 1
                  error('Segment:Constructor:InputFormat',...
                     'Windows for all processes must be equal');
               end
            else
               self.window = par.window;
            end
            if isempty(par.offset)
               offset = cell.uniqueRows(cellfun(@(x) x.offset,self.processes','uni',0));
               if numel(offset) > 1
                  error('Segment:Constructor:InputFormat',...
                     'Offsets for all processes must be equal');
               end
            else
               self.offset = par.offset;
            end
         end

         self.labels = p.Results.labels;
         
         % Add Segment reference to all child processes
         cellfun(@(x) set(x,'segment',self),self.processes,'uni',0);
         
         % Register listeners
         if par.coordinateProcesses
            temp = cellfun(@(x) addlistener(x,'window','PostSet',@self.windowChange),self.processes,'uni',0);
            self.listeners_.window = [temp{:}];

            temp = cellfun(@(x) addlistener(x,'offset','PostSet',@self.offsetChange),self.processes,'uni',0);
            self.listeners_.offset = [temp{:}];
            
            temp = cellfun(@(x) addlistener(x,'isSyncing',@self.syncChange),self.processes,'uni',0);
            self.listeners_.sync = [temp{:}];
         end
         self.coordinateProcesses = par.coordinateProcesses;
      end
      
      
      function list = get.type(self)
         list = cellfun(@(x) class(x),self.processes,'uni',0);
      end
      
      function proc = get.sampledProcess(self)
         proc = extract(self,'SampledProcess','type');
      end
      
      function proc = get.pointProcess(self)
         proc = extract(self,'PointProcess','type');
      end
      
      function proc = get.eventProcess(self)
         proc = extract(self,'EventProcess','type');
      end
      
      function tStart = get.tStart(self)
         tStart = unique(cellfun(@(x) x.tStart,self.processes));
      end
      
      function set.tStart(self,tStart)
         for i = 1:numel(self.processes)
            self.processes{i}.tStart = tStart;
         end
         self.tStart = tStart;
      end

      function tEnd = get.tEnd(self)
         tEnd = unique(cellfun(@(x) x.tEnd,self.processes));
      end
      
      function set.tEnd(self,tEnd)
         for i = 1:numel(self.processes)
            self.processes{i}.tEnd = tEnd;
         end
         self.tEnd = tEnd;
      end
      
      function offset = get.offset(self)
         offset = cell.uniqueRows(cellfun(@(x) x.offset,self.processes','uni',0));
         offset = offset{1};
      end
      
      function set.offset(self,offset)
         for i = 1:numel(self.processes)
            self.processes{i}.offset = offset;
         end
      end

      function window = get.window(self)
         window = cell.uniqueRows(cellfun(@(x) x.window,self.processes','uni',0));
         window = window{1};
      end
      
      function set.window(self,window)
         for i = 1:numel(self.processes)
            self.processes{i}.window = window;
         end
      end
      
      function set.labels(self,labels)
         n = numel(self.processes);
         if isempty(labels)
            self.labels = arrayfun(@(x) ['sid' num2str(x)],1:n,'uni',0);
         elseif iscell(labels)
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
      obj = restrictByInfo(self,key,prop,value,varargin)
      self = reset(self)
      
      % add process
      
      %plot
      
      function delete(self)
         %disp('Segment delete');
         if ~isempty(self.processes)
            cellfun(@(x) set(x,'segment',[]),self.processes,'uni',0);
         end
      end
   end
   
   methods(Access = protected)
      % need to check whether coordinating
      function offsetChange(self,varargin)
         disp('coordinating segment offset');
         [self.listeners_.offset.Enabled] = deal(false);
         ind = cellfun(@(x) x==varargin{2}.AffectedObject,self.processes);
         offset = varargin{2}.AffectedObject.offset;
         cellfun(@(x) x.setOffset(offset),self.processes(~ind),'uni',0);
         [self.listeners_.offset.Enabled] = deal(true);
      end
      function windowChange(self,varargin)
         disp('coordinating segment window');
         [self.listeners_.window.Enabled] = deal(false);
         ind = cellfun(@(x) x==varargin{2}.AffectedObject,self.processes);
         window = varargin{2}.AffectedObject.window;
         cellfun(@(x) x.setWindow(window),self.processes(~ind),'uni',0);
         [self.listeners_.window.Enabled] = deal(true);
      end
      function syncChange(self,varargin)
         disp('coordinating segment sync');
         [self.listeners_.offset.Enabled] = deal(false);
         [self.listeners_.window.Enabled] = deal(false);
         [self.listeners_.sync.Enabled] = deal(false);
         disp('listeners are off');
         par = varargin{2}.par;
         cellfun(@(x) x.sync(par.event,par),self.processes,'uni',0);
         [self.listeners_.offset.Enabled] = deal(true);
         [self.listeners_.window.Enabled] = deal(true);
         [self.listeners_.sync.Enabled] = deal(true);
      end
   end
   
   methods(Static)
      %obj = loadobj(S)
   end
end