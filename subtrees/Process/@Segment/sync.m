
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
         temp = extract(self(i),'EventProcess','type');
         if numel(temp) > 1
            error('multiple matches for EventProcess');
         else
            temp = temp{1};
         end
      else
         temp = extract(self(i),p.Results.eventProcessName,'label');
      end
      event = temp.find(eventPars);
   else
      event = p.Results.event;
   end
   
   if numel(event) == 1
      if isempty(syncPars)
         cellfun(@(x) x.sync(event),self(i).processes,'uni',0);
      else
         cellfun(@(x) x.sync(event,syncPars),self(i).processes,'uni',0);
      end
      self(i).validSync = 1;
   elseif numel(event) > 1
      % pick according to policy
      self(i).validSync = numel(event);
   else
      %error('incorrect number of events');
      self(i).validSync = false;
   end
end
