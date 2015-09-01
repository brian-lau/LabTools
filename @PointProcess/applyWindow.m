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

nWindow = size(self.window,1);

times = self.times;
if isempty(times) % FIXME, is this only for constructor?
   return;
end

nTimes = size(times,2);
window = self.window;
values = self.values;

windowedTimes = cell(nWindow,nTimes);
windowedValues = cell(nWindow,nTimes);
for i = 1:nWindow
   for j = 1:nTimes
      ind = (times{j}(:,1)>=window(i,1)) & (times{j}(:,1)<=window(i,2));
      windowedTimes{i,j} = times{j}(ind,:);
      windowedValues{i,j} = values{j}(ind);
   end
end
self.times = windowedTimes;
self.values = windowedValues;
