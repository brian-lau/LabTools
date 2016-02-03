% Window original event times, setting
%     times
%     values
%     index
%     isValidWindow
% TODO
% o Windows are inclusive on both sides, does this make sense???
% o How to handle different # of windows (ie, when current # of windows
%   does not match requested number of windows

function applyWindow(self)

if isempty(self.times)
   return;
end

nTimes = size(self.times,2);
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
      ind = (self.times{idx,j}(:,1)>=window(i,1)) & (self.times{idx,j}(:,1)<=window(i,2));
      windowedTimes{i,j} = self.times{idx,j}(ind,:);
      windowedValues{i,j} = self.values{idx,j}(ind);
   end
end
self.times = windowedTimes;
self.values = windowedValues;
