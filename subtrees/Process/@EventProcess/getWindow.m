% GETWINDOW - Get start/end times for windows between/within events
%
%     window = getWindow(EventProcess,varargin)
%     window = EventProcess.getWindow(varargin)
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% INPUTS
%     method - string, optional, default = 'between'
%              One of following indicating
%              'within'  - start/end times of requested events
%              'between' - start/end times between events
%     minDuration - scalar>0, optional, default = 0
%              Minimum duration of window to be retained
%
%     Remaning inputs are passed through to EventProcess.find().
%
% OUTPUTS
%     window - [n x 2] matrix of window start/end times
%
% EXAMPLES
%     fix = metadata.Label('name','fix');
%     cue = metadata.Label('name','cue');
%     artifact = metadata.Label('name','artifact');
%     button = metadata.Label('name','button');
%
%     e(1) = metadata.event.Stimulus('tStart',0.5,'tEnd',1,'name',fix);
%     e(2) = metadata.event.Artifact('tStart',1,'tEnd',1.5,'name',artifact);
%     e(3) = metadata.event.Stimulus('tStart',2,'tEnd',3,'name',cue);
%     e(4) = metadata.event.Artifact('tStart',3,'tEnd',4,'name',artifact);
%     e(5) = metadata.event.Artifact('tStart',5,'tEnd',8,'name',artifact);
%     e(6) = metadata.event.Response('tStart',4.5,'tEnd',5.5,'name',button);
%
%     events = EventProcess('events',e,'tStart',0,'tEnd',10);
%     plot(events);
%
%     % Construct windows between artifacts. Note that there the first
%     % and last window are created because the relative window of the
%     % EventProcess extends beyond its events.
%     window = events.getWindow('eventType','Artifact')
%
% SEE ALSO
%     find

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process

% TODO
%  o multiple windows
function window = getWindow(self,varargin)

p = inputParser;
p.KeepUnmatched = true;
p.FunctionName = 'EventProcess getWindow method';
p.addParameter('method','between',@(x) any(strcmp(x,...
   {'between' 'within'})));
p.addParameter('minDuration',0,@(x) isscalar(x)&&(x>=0))
p.parse(varargin{:});
matchPar = p.Unmatched; % pass through to find
par = p.Results;

if ~isempty(fieldnames(matchPar))
   if ~isfield(matchPar,'policy')
      matchPar.policy = 'all';
   end
   ev = self.find(matchPar);
   ev = ev{1};
else
   ev = self.values{1};
end

evWindow = [[ev.tStart]' , [ev.tEnd]'];

switch par.method
   case 'between'
      ind = (evWindow(:,1) >= self.relWindow(1)) & (evWindow(:,2) <= self.relWindow(2));
      evWindow = evWindow(ind,:);

      window = zeros(size(evWindow,1)+1,2);
      for i = 1:size(evWindow,1)-1
         window(i+1,1) = evWindow(i,2);
         window(i+1,2) = evWindow(i+1,1);
      end
      
      % Determine if there is a window preceding first event
      if evWindow(1,1) > self.relWindow(1)
         window(1,1) = self.relWindow(1);
         window(1,2) = evWindow(1,1);
      else
         window(1,:) = [];
      end
      
      % Determine if there is a window following last event
      if evWindow(end,2) < self.relWindow(2)
         window(end,1) = evWindow(end,2);
         window(end,2) = self.relWindow(2);
      else
         window(end,:) = [];
      end
   case 'within'
      window = evWindow;
end

% This will also exlcude negative windows from overlapping events
ind = diff(window,1,2) < par.minDuration;
window(ind,:) = [];