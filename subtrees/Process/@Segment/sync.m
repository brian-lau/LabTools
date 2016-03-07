
% in the case of vector Segment, metadata.Event
% filter for Event, take start or end time as event
% handle case of missing event?
% 
% Segment is scalar
% same event for each process
% different event for each process (where each process is scalar)
% different event for each process (where each process could be vector)
%   sync all to same event

function self = sync(self,event,varargin)

p = inputParser;
p.KeepUnmatched= true;
p.FunctionName = 'Segment sync';
p.addOptional('event',[],@(x) isnumeric(x) || isa(x,'metadata.Event'));
p.addOptional('window',[],@(x) isnumeric(x) && (size(x,1)==1) && (size(x,2)==2)); 
p.addOptional('eventProcessName',[],@ischar);
p.parse(event,varargin{:});

validSyncParams = {'processTime' 'eventStart'};
eventPars = p.Unmatched;

if ~isempty(p.Results.window)
   syncPars.window = p.Results.window;
else
   syncPars = [];
end

% Separate parameters for sync and EventProcess.find
if ~isempty(fieldnames(eventPars))
   fn = fieldnames(eventPars);
   match = intersect(fn,validSyncParams);
   for i = 1:numel(match)
      syncPars.(match{i}) = eventPars.(match{i});
      eventPars = rmfield(eventPars,match{i});
   end
end

disableSegmentListeners(self);
for i = 1:numel(self)
   if isempty(p.Results.event)
      % Pull event out of EventProcess
      if isempty(p.Results.eventProcessName)
         if numel(self(i).eventProcess) > 1
            error('Multiple EventProcesses in Segment, specify by name');
          else
            temp = self(i).eventProcess;
         end
      else
         temp = extract(self(i),p.Results.eventProcessName,'label');
      end
      % Will return Null event defined in EventProcess if nothing found
      
      event = temp.find(eventPars);
   elseif isa(p.Results.event,'metadata.Event')
      % FIXME, check dimensions for scalar event
      % FIXME, need an assert above to ensure dimensions match
      event = p.Results.event(i);
   end

   if numel(event) == 1
      if ~strcmp(event.name,'NULL')
         if isempty(syncPars)
            cellfun(@(x) x.sync__(event),self(i).processes,'uni',0);
         else
            cellfun(@(x) x.sync__(event,syncPars),self(i).processes,'uni',0);
         end
      end
      self(i).validSync = event;
   elseif numel(event) > 1
      %TODO pick according to policy
      self(i).validSync = numel(event);
      error('multiple events, policy selector not done');
   else
      error('incorrect number of events');
   end
end
enableSegmentListeners(self);
