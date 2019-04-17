function ev = detect(self,threshold)

s = copy(self);

if isa(threshold,'function_handle')
   func = threshold;
else
   % TODO : implement standard detectors
end
s.map(func);
keyboard

for i = 1:numel(s)
   ind = s(i).values{1};
   times = s(i).times{1};
   %times = repmat(times,s(i).n);
   
   dind = diff(ind); % +1 event goes hi, -1 event goes lo
   
   for j = 1:s(i).n
      ascend = times(dind(:,j)==1);
      descend = times(dind(:,j)==-1);
      if isempty(ascend) || isempty(descend)
         %events{i,j} = [NaN NaN];
         events{i,j} = [];
      else
         if descend(1) < ascend(1)
            descend(1) = [];
         end
         
         if ascend(end) > descend(end)
            ascend(end) = [];
         end
         
         events{i,j} = [ascend , descend];
      end
      
      n = size(events{i,j},1);
      ev(n) = metadata.event.Generic();
      
      tStart = num2cell(events{i,j}(:,1));
      [ev.tStart] = deal(tStart{:});
      tEnd = num2cell(events{i,j}(:,2));
      [ev.tEnd] = deal(tEnd{:});
      
      evv{j} = ev;
      clear ev;
   end
   %ep(i) = EventProcess(evv,'tStart',self(i).tStart,'tEnd',self(i).tEnd);
end

% n = size(events,1);
% ev(n) = metadata.event.Generic();
% 
% tStart = num2cell(events(:,1));
% [ev.tStart] = deal(tStart{:});
% tEnd = num2cell(events(:,2));
% [ev.tEnd] = deal(tEnd{:});
% 
% ep = EventProcess(ev,'tStart',self.tStart,'tEnd',self.tEnd);
% 
% for 