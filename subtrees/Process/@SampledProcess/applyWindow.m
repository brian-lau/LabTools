% Window original event times, setting
%     times
%     values
%     index
%     isValidWindow

% TODO
%   o Windows are inclusive on both sides, does this make sense???

function applyWindow(self)

if isempty(self.times_)
   return;
end

% NaN-pad when window extends beyond process. This extension is
% done to the nearest sample that fits in the window.
nWindow = size(self.window,1);
window = self.window;
minWin = min(window(:,1));
maxWin = max(window(:,2));

pre = self.extendPre(self.tStart,minWin,1/self.Fs_);
preV = nan(size(pre,1),size(self.values_,2));
post = self.extendPost(self.tEnd,maxWin,1/self.Fs_);
postV = nan(size(post,1),size(self.values_,2));
times = [pre ; self.times_ ; post];
values = [preV ; self.values_ ; postV];

windowedTimes = cell(nWindow,1);
windowedValues = cell(nWindow,1);
windowIndex = cell(nWindow,1);
isValidWindow = false(nWindow,1);
for i = 1:nWindow
   ind = (times>=window(i,1)) & (times<=window(i,2));
   windowedTimes{i,1} = times(ind);
   windowedValues{i,1} = values(ind,:); % FIXME, only works for 2D
   windowIndex{i,1} = find(ind);
   if (window(i,1)>=self.tStart) && (window(i,2)<=self.tEnd)
      isValidWindow(i) = true;
   else
      isValidWindow(i) = false;
   end
end
self.times = windowedTimes;
self.values = windowedValues;
self.index = windowIndex;
self.isValidWindow = isValidWindow;
