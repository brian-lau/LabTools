%%
% Create array of SampledProcesses
s = SampledProcess(randn(20,20)+5*eye(20));
l = s.labels;
for i = 2:50
   s(i) = SampledProcess(randn(20,20)+5*eye(20),'labels',l);
end

% Create array of EventProcesses that correspond to above
fix = metadata.Label('name','fix');
cue = metadata.Label('name','cue');
button = metadata.Label('name','button');
for i = 1:50
   t = rand;
   e(1) = metadata.event.Stimulus('tStart',t,'tEnd',t+1,'name',fix);
   t = 2+rand;
   e(2) = metadata.event.Stimulus('tStart',t,'tEnd',t+1,'name',cue);
   t = 3+rand;
   e(3) = metadata.event.Response('tStart',t,'tEnd',t+2,'name',button,'experiment',metadata.Experiment);
   events(i) = EventProcess('events',e,'tStart',0,'tEnd',10);
end

% Plot SampledProcess
h = plot(s);
% Add events to the plot
plot(events,'handle',h);