% Generate EventProcess matching SampledProcess

function ep = annotate(self)

% Create array of EventProcesses that correspond to above, using a null
% event as a placeholder
null = metadata.Event('name','NULL','tStart',NaN,'tEnd',NaN);
for i = 1:numel(self)
   ep(i) = EventProcess('events',null,'tStart',self(i).tStart,'tEnd',self(i).tEnd);
end

h = plot(self);

% Add events to the plot
%plot(events,'handle',h);
% If you prefer non-overlapping, try below instead
plot(ep,'handle',h,'overlap',-.05,'stagger',true);
