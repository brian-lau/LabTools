
fix = metadata.Label('name','fix');
cue = metadata.Label('name','cue');
button = metadata.Label('name','button');

e(1) = metadata.event.Stimulus('tStart',0.5,'tEnd',1,'name',fix);
e(2) = metadata.event.Stimulus('tStart',2,'tEnd',3,'name',cue);
e(3) = metadata.event.Response('tStart',5,'tEnd',6,'name',button,'experiment',metadata.Experiment);

events = EventProcess('events',e,'tStart',0,'tEnd',10);

e(1) = metadata.event.Stimulus('tStart',0.5,'tEnd',1,'name',fix,'color','r');
e(2) = metadata.event.Stimulus('tStart',2,'tEnd',3,'name',cue,'color','b');
e(3) = metadata.event.Response('tStart',5,'tEnd',6,'name',button,'experiment',metadata.Experiment,'color','g');

events = EventProcess('events',e,'tStart',0,'tEnd',10);

% tic;
% for i = 1:1000
%    events.values;
% end
% toc

fix = metadata.Label('name','fix');
cue = metadata.Label('name','cue');
button = metadata.Label('name','button');

e(1) = metadata.event.Stimulus('tStart',0.5,'tEnd',1,'name',fix);
e(2) = metadata.event.Stimulus('tStart',2,'tEnd',3,'name',cue);
e(3) = metadata.event.Response('tStart',5,'tEnd',6,'name',button,'experiment',metadata.Experiment);

events(1) = EventProcess('events',e,'tStart',0,'tEnd',10);
events(2) = EventProcess('events',e,'tStart',0,'tEnd',10);
