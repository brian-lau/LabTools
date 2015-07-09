
function self = sync(self,event,varargin)

p = inputParser;
p.KeepUnmatched= true;
p.FunctionName = 'Segment sync';
p.addOptional('event',[],@(x) isnumeric(x) || isa(x,'metadata.Event'));
p.addOptional('window',[],@(x) isnumeric(x) && (size(x,1)==1) && (size(x,2)==2)); 
p.addOptional('eventProcessName',[],@ischar);
p.parse(event,varargin{:});

validSyncParams = {'commonTime' 'interpMethod' 'resample' 'eventStart'};
eventPars = p.Unmatched;

if ~isempty(p.Results.window)
   syncPars.window = p.Results.window;
else
   syncPars = [];
end

if ~isempty(fieldnames(eventPars))
   fn = fieldnames(eventPars);
   match = intersect(fn,validSyncParams);
   for i = 1:numel(match)
      syncPars.(match{i}) = eventPars.(match{i});
      eventPars = rmfield(eventPars,match{i});
   end
end

% in the case of vector Segment, metadata.Event
% filter for Event, take start or end time as event
% handle case of missing event?
% 
% Segment is scalar
% same event for each process
% different event for each process (where each process is scalar)
% different event for each process (where each process could be vector)
%   sync all to same event

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
      event = p.Results.event(i);
   end

   if numel(event) == 1
      if ~strcmp(event.name,'NULL')
         if isempty(syncPars)
            cellfun(@(x) x.sync(event),self(i).processes,'uni',0);
         else
            cellfun(@(x) x.sync(event,syncPars),self(i).processes,'uni',0);
         end
         %self(i).validSync = true;
      else
         %self(i).validSync = false;%metadata.Event('name','NULL','tStart',NaN,'tEnd',NaN)
      end
      self(i).validSync = event;
   elseif numel(event) > 1
      %TODO pick according to policy
      self(i).validSync = numel(event);
      error('multiple events, policy selector not done');
   else
      error('incorrect number of events');
      %self(i).validSync = false;
   end
end