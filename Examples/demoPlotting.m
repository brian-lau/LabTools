%% Overlay EventProcess and SampledProcess
% Create array of SampledProcesses
% Create an initial process, with default labels
s = SampledProcess(randn(20,20)+5*eye(20));
% Pull these labels out and reuse them for the remaining elements. This
% means that each channel with the same label in each element will be
% have matching labels. Otherwise, the default would generate unique labels
% for each channel.
l = s.labels;
for i = 2:20
   s(i) = SampledProcess(randn(20,20)+5*eye(20),'labels',l);
end

% Create array of EventProcesses that correspond to above
fix = metadata.Label('name','fix');
cue = metadata.Label('name','cue');
button = metadata.Label('name','button');
for i = 1:20
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
%plot(events,'handle',h);
% If you prefer non-overlapping, try below instead
plot(events,'handle',h,'overlap',-.05,'stagger',true);

%%%%%%%%%%%%%%%%%%%%%%%
%% Overlay two SampledProcesses
t = (0:.001:1)';
s = SampledProcess(cos(2*pi*10*t)+cos(2*pi*50*t),'Fs',1000);
s2 = s.new().notch('order',6,'F',50);
s2.labels.color = [1 0 0];
h = plot(s);
plot(s2,'handle',h);

%%%%%%%%%%%%%%%%%%%%%%%
s = SampledProcess(randn(10000,50));
l = s.labels;
for i = 2:200
   s(i) = SampledProcess(randn(10000,50),'labels',l);
end
h = plot(s);
