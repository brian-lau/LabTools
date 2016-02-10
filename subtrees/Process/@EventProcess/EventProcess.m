% Event processes

classdef(CaseInsensitiveProperties) EventProcess < PointProcess         
   properties(SetAccess = private, Dependent)
      duration           % duration of events in windows
      isValidEvent       % start/end time of events in windows?
   end
   properties
      nullEvent = metadata.Event('name','NULL','tStart',NaN,'tEnd',NaN)
   end
   properties(SetAccess = protected, Hidden, Transient)
      updateEventListener_@event.proplistener % listener
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
         p.KeepUnmatched= true;
         p.FunctionName = 'EventProcess constructor';
         p.addParameter('Fs',1000,@(x) isnumeric(x) && isscalar(x));
         p.addParameter('events',[],@(x) iscell(x) || isa(x,'metadata.Event') );
         p.addParameter('times',[],@(x) isnumeric(x) || iscell(x));
         p.parse(varargin{:});
         par = p.Results;
         args = p.Unmatched;
         args.Fs = p.Results.Fs;
         
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
               end
               events = {par.events};
               times = cellfun(@(x) vertcat(x.time),events,'uni',0);
            end

            args.times = cellfun(@(x) roundToSample(x,1/args.Fs),times,'uni',0);
            args.values = events;
         else
            args = {};
         end
         
         self = self@PointProcess(args);         
         self.updateEventListener_ = addlistener(self,'values','PreGet',@self.updateEventTimes);
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
         % start/end time of events fall within windows?
         if isempty(self.times)
            bool = false;
         else
            bool = cellfun(@(times,win) (times(:,1)>=win(:,1))&(times(:,2)<=win(:,2)),...
               self.times,mat2cell(self.window,ones(1,size(self.window,1)),2),'uni',0);
         end
      end
      
      function updateEventTimes(self,varargin)
         % Adjust times stored in Events
         for i = 1:size(self.times,1) % channels
            for j = 1:size(self.times,2) % windows
               temp = self.values{i,j};
               times = self.times{i,j};
               for k = 1:numel(temp)
                  temp(k).tStart = times(k,1);
                  temp(k).tEnd = times(k,2);
               end
               self.values{i,j} = temp;
            end
         end
      end
      
      ev = find(self,varargin)
      
      % add event
      self = insert(self,ev,labels)
      % remove event
      
      %% Display
      h = plot(self,varargin)
      
      function S = saveobj(self)
         if 1
            S = self;
         else
            %disp('event process saveobj');
            delete(self.updateEventListener_);
            % Converting to bytestream prevents removal of transient/dependent
            % properties, so we have to do this manually
            warning('off','MATLAB:structOnObject');
            S = getByteStreamFromArray(struct(self));
            warning('on','MATLAB:structOnObject');
         end
      end
   end
   
   methods(Static)
      obj = loadobj(S)
   end
end

