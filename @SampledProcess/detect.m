function ev = detect(self,threshold)

s = copy(self);

if isa(threshold,'function_handle')
   func = threshold;
else
   % TODO : implement standard detectors
end
s.map(func);

ind = s.values{1};
times = s.times{1};

dind = diff(ind); % +1 event goes hi, -1 event goes lo
ascend = times(dind==1);
descend = times(dind==-1);

if isempty(ascend) || isempty(descend)
   events = [NaN NaN];
else
   if descend(1) < ascend(1)
      descend(1) = [];
   end
   
   if ascend(end) > descend(end)
      ascend(end) = [];
   end
   
   events = [ascend , descend];
end

ev = events;

% n = size(events,1);
% ev(n) = metadata.event.Generic();
% 
% tStart = num2cell(events(:,1));
% [ev.tStart] = deal(tStart{:});
% tEnd = num2cell(events(:,2));
% [ev.tEnd] = deal(tEnd{:});
% 
%ep = EventProcess(ev,'tStart',self.tStart,'tEnd',self.tEnd);