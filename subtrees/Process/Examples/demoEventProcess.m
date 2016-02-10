e(1) = metadata.event.Stimulus('tStart',0.5,'tEnd',1,'name','fix');
e(2) = metadata.event.Stimulus('tStart',2,'tEnd',3,'name','cue');
e(3) = metadata.event.Response('tStart',5,'tEnd',6,'name','button');


events = EventProcess('events',e,'tStart',0,'tEnd',10);

e(1) = metadata.event.Stimulus('tStart',0,'tEnd',1,'name','fix');
e(2) = metadata.event.Stimulus('tStart',0,'tEnd',2,'name','cue');
e(3) = metadata.event.Response('tStart',0,'tEnd',3,'name','button');

events = EventProcess('times',[0 1;2 3;4 5],'events',e,'tStart',0,'tEnd',10);

tic;
for i = 1:1000
   events.values;
end
toc