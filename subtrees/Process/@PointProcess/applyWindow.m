% Window original event times, setting
%     times
%     values
%     index
%     isValidWindow
% TODO
% Windows are inclusive on both sides, does this make sense???

function applyWindow(self)

nWindow = size(self.window,1);
times = self.times_;
if isempty(times)
   return;
end

nTimes = size(times,2);
if all(cellfun(@(x) isa(x,'handle'),self.values_))
   values = cellfun(@(x) copy(x),self.values_,'uni',0);
else
   values = self.values_;
end
window = self.window;
windowedTimes = cell(nWindow,nTimes);
windowedValues = cell(nWindow,nTimes);
windowIndex = cell(nWindow,nTimes);
isValidWindow = false(nWindow,1);
for i = 1:nWindow
   for j = 1:nTimes
      ind = (times{j}(:,1)>=window(i,1)) & (times{j}(:,1)<=window(i,2));
      windowedTimes{i,j} = times{j}(ind,:);
      windowedValues{i,j} = values{j}(ind);
      windowIndex{i,j} = find(ind);
      if (window(i,1)>=self.tStart) && (window(i,2)<=self.tEnd)
         isValidWindow(i) = true;
      else
         isValidWindow(i) = false;
      end
   end
end
self.times = windowedTimes;
self.values = windowedValues;
self.index = windowIndex;
self.isValidWindow = isValidWindow;
