% Window event times, setting
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

nWindowReq = size(self.window,1);
nWindowOrig = numel(self.times);
if nWindowOrig > 1
   assert(nWindowReq==nWindowOrig,'monkey!');
end

window = self.window;
windowedTimes = cell(nWindowReq,1);
windowedValues = cell(nWindowReq,1);
for i = 1:nWindowReq
   minWin = min(window(i,1));
   maxWin = max(window(i,2));
   if nWindowOrig == 1
      idx = 1;
   else
      idx = i;
   end
   
   times = self.times{idx};
   values = self.values{idx};
   tStart = min(times);
   tEnd = max(times);
   dim = size(values);
   dim = dim(2:end); % leading dim is always time
   trailingInd = repmat({':'},1,numel(dim));
   
   % NaN-pad when window extends beyond process. This extension is
   % done to the nearest sample that fits in the window.
   [preT,preV] = self.extendPre(tStart,minWin,1/self.Fs,dim);
   [postT,postV] = self.extendPost(tEnd,maxWin,1/self.Fs,dim);
   
   ind = (times>=window(i,1)) & (times<=window(i,2));
   windowedTimes{i,1} = [preT ; times(ind) ; postT];
   windowedValues{i,1} = [preV ; values(ind,trailingInd{:}) ; postV];
end

self.times = windowedTimes;
self.values = windowedValues;
