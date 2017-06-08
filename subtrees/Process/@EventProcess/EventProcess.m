% Event process

classdef(CaseInsensitiveProperties) EventProcess < PointProcess         
   properties(SetAccess = private, Dependent)
      duration           % duration of events in windows
      isValidEvent       % start/end time of events in windows?
   end
   properties
      null = metadata.Event('name','NULL','tStart',NaN,'tEnd',NaN)
   end
   
   %%
   methods
      %% Constructor
      function self = EventProcess(varargin)
         if mod(nargin,2)==1 && ~isstruct(varargin{1})
            assert(isa(varargin{1},'metadata.Event'),...
               'EventProcess:Constructor:InputFormat',...
                  'Single inputs must be passed in as array of metadata.Events');
            varargin = [{'events'} varargin];
         end
         
         p = inputParser;
         p.KeepUnmatched = true;
         p.FunctionName = 'EventProcess constructor';
         p.addParameter('events',[],@(x) iscell(x) || isa(x,'metadata.Event') );
         p.addParameter('times',[],@(x) isnumeric(x) || iscell(x));
         p.parse(varargin{:});
         par = p.Results;
         
         % Pass through to PointProcess constructor
         args = p.Unmatched;
         
         if ~isempty(par.events)
            if ~isempty(par.times)
               if iscell(par.times) && iscell(par.events)
                  times = par.times;
                  events = par.events;
               elseif ismatrix(par.times) && ismatrix(par.events)
                  times = {par.times};
                  events = {par.events};
               else
                  error('mismatched');
               end
               assert(all(cellfun(@(x,y) all(size(x,1)==numel(y)),times,events,'uni',1)),...
                  'EventProcess:constructor:InputValue',...
                  'nonmatching dimensions for times and events');
            else
               if iscell(par.events)
                  assert(all(cellfun(@(x) isa(x,'metadata.Event'),par.events)));                  
                  events = par.events;
                  times = cellfun(@(x) vertcat(x.time),events,'uni',0);
               else
                  events = {par.events};
                  times = {[vertcat(par.events.tStart),vertcat(par.events.tEnd)]};
               end
            end

            args.times = times;
            args.values = events;
         else
            args = {};
         end
         
         self = self@PointProcess(args);         
      end
      
      function duration = get.duration(self)
         % duration of events within windows
         if isempty(self.times)
            duration = NaN;
         else
            duration = cellfun(@(x) x(:,2)-x(:,1),self.times,'uni',0);
         end
      end
      
      function bool = get.isValidEvent(self)
         % start AND end time of events fall within windows?
         if isempty(self.times)
            bool = false;
         else
            bool = cellfun(@(times,win) (times(:,1)>=win(:,1))&(times(:,2)<=win(:,2)),...
               self.times,mat2cell(self.window,ones(1,size(self.window,1)),2),'uni',0);
         end
      end
      
      function chop(self,varargin)
         % Call superclass method to split
         chop@Process(self,varargin{:});
         
         % Update metadata.Event times
         for i = 1:numel(self)
            self(i).updateEventTimes();
         end
         
         if nargout == 0
            % Currently Matlab OOP doesn't allow the handle to be
            % reassigned, ie self = obj, so we do a silent pass-by-value
            % http://www.mathworks.com/matlabcentral/newsreader/view_thread/268574
            assignin('caller',inputname(1),self);
         end
      end
      
      updateEventTimes(self,varargin)
      
      [ev,selection] = find(self,varargin)
      
      window = getWindow(self,varargin)
      
      % add event
      self = insert(self,ev,labels)
      % remove event (overload)
      self = remove(self,times,labels)

      %% Display
      h = plot(self,varargin)
      
      function print(self)
         for i = 1:numel(self)
            temp = self(i).values{1};
            try
               rownames = arrayfun(@(x) x.name.name,temp,'uni',0);
            catch err
               if strcmp(err.identifier,'MATLAB:structRefFromNonStruct')
                  rownames = arrayfun(@(x) x.name,temp,'uni',0);
               else
                  rethrow(err);
               end
            end
            tStart = [temp.tStart]';
            tEnd = [temp.tEnd]';
            duration = [temp.duration]';
            disp(table(tStart,tEnd,duration,'RowNames',rownames))
         end
      end
      
      function S = saveobj(self)
         if ~self.serializeOnSave
            S = self;
         else
            %disp('event process saveobj');
            % Converting to bytestream prevents removal of transient/dependent
            % properties, so we have to do this manually
            warning('off','MATLAB:structOnObject');
            S = getByteStreamFromArray(struct(self));
            warning('on','MATLAB:structOnObject');
         end
      end
   end
   
   methods(Access = protected)
      applyWindow(self)
      applyOffset(self,offset)
   end
   
   methods(Static)
      obj = loadobj(S)
   end
end

