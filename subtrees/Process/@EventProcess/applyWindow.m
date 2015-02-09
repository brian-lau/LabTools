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

values = self.values_;
%cellfun(@(x) x.reset,values,'uni',0);
for i = 1:numel(values)
   %values{i}.reset();
   [values{i}.tStart] = list(times{i}(:,1));
   [values{i}.tEnd] = list(times{i}(:,2));
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
