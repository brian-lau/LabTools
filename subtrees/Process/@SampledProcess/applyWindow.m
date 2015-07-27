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
tStart = min(self.times{1});
tEnd = max(self.times{1});

if (minWin<tStart) && (maxWin>tEnd)
   pre = self.extendPre(tStart,minWin,1/self.Fs);
   preV = nan(size(pre,1),size(self.values_,2));
   post = self.extendPost(tEnd,maxWin,1/self.Fs);
   postV = nan(size(post,1),size(self.values_,2));
   times = [pre ; self.times{1} ; post];
   values = [preV ; self.values{1} ; postV];
elseif (minWin<tStart) && (maxWin<=tEnd)
   pre = self.extendPre(tStart,minWin,1/self.Fs);
   preV = nan(size(pre,1),size(self.values_,2));
   times = [pre ; self.times{1}];
   values = [preV ; self.values{1}];
elseif (minWin>=tStart) && (maxWin>tEnd)
   post = self.extendPost(tEnd,maxWin,1/self.Fs);
   postV = nan(size(post,1),size(self.values_,2));
   times = [self.times{1} ; post];
   values = [self.values{1} ; postV];
else
   times = self.times_;
   values = self.values_;
end

windowedTimes = cell(nWindow,1);
windowedValues = cell(nWindow,1);
for i = 1:nWindow
   ind = (times>=window(i,1)) & (times<=window(i,2));
   windowedTimes{i,1} = times(ind);
   windowedValues{i,1} = values(ind,:); % FIXME, only works for 2D
end
self.times = windowedTimes;
self.values = windowedValues;
