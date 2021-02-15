function [events,vmax] = detect(self,threshold)

s = copy(self);

if isa(threshold,'function_handle')
   func = threshold;
else
   % TODO : implement standard detectors
end
s.map(func);

for i = 1:numel(s)
   ind = s(i).values{1};         % indices where signal exceeds threshold
   values = self(i).values{1};
   times = s(i).times{1};
   
   dind = diff(ind); % +1 event goes hi, -1 event goes lo
   
   for j = 1:s(i).n
      ascend = times(dind(:,j)==1);
      descend = times(dind(:,j)==-1);
      if isempty(ascend) || isempty(descend)
         events{i,j} = [];
      else
         ascend_ind = find(dind(:,j)==1);
         descend_ind = find(dind(:,j)==-1);
         if descend(1) < ascend(1)
            descend(1) = [];
            descend_ind(1) = [];
         end
         
         if ascend(end) > descend(end)
            ascend(end) = [];
            ascend_ind(end) = [];
         end
         
         events{i,j} = [ascend , descend];
         if nargout == 2
            vmax{i,j} = arrayfun(@(u,d) max(values(u:d,j)), ascend_ind, descend_ind);
         end
      end
      
   end
end