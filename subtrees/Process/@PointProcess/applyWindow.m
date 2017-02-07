% Window original event times, setting
%     times
%     values

function applyWindow(self)

if isempty(self.times)
   return;
end

nTimes = self.n;
nWindowReq = size(self.window,1);
nWindowOrig = size(self.times,1);
if nWindowOrig > 1
   assert(nWindowReq==nWindowOrig,'monkey!');
end

window = self.window;
windowedTimes = cell(nWindowReq,nTimes);
windowedValues = cell(nWindowReq,nTimes);
for i = 1:nWindowReq
   if nWindowOrig == 1
      idx = 1;
   else
      idx = i;
   end
   
   for j = 1:nTimes
      x = self.times{idx,j};
      y = self.values{idx,j};
      ind = (x(:,1)>=window(i,1)) & (x(:,1)<=window(i,2));
      if all(ind)
         windowedTimes{i,j} = x;
         windowedValues{i,j} = y;
      else
         windowedTimes{i,j} = x(ind,:);
         windowedValues{i,j} = y(ind);
      end
   end
end
self.times = windowedTimes;
self.values = windowedValues;
