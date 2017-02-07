% Adjust times stored in Events (metadata.Events)
function updateEventTimes(self,varargin)

times = self.times;
values = self.values;
[nWindow,nChan] = size(times);

for i = 1:nWindow
   for j = 1:nChan
      temp = num2cell(times{i,j});
      [values{i,j}.tStart,values{i,j}.tEnd] = temp{:,:};
   end
end

self.values = values;
