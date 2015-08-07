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

%keyboard

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
   % NaN-pad when window extends beyond process. This extension is
   % done to the nearest sample that fits in the window.
   tStart = min(self.times{idx});
   tEnd = max(self.times{idx});
   dim = size(self.values{idx});
   dim = dim(2:end); % leading dim is always time
   if (minWin<tStart) && (maxWin>tEnd)
      [pre,preV] = self.extendPre(tStart,minWin,1/self.Fs,dim);
      [post,postV] = self.extendPost(tEnd,maxWin,1/self.Fs,dim);
      times = [pre ; self.times{idx} ; post];
      values = [preV ; self.values{idx} ; postV];
   elseif (minWin<tStart) && (maxWin<=tEnd)
      [pre,preV] = self.extendPre(tStart,minWin,1/self.Fs,dim);
      times = [pre ; self.times{idx}];
      values = [preV ; self.values{idx}];
   elseif (minWin>=tStart) && (maxWin>tEnd)
      [post,postV] = self.extendPost(tEnd,maxWin,1/self.Fs,dim);
      times = [self.times{idx} ; post];
      values = [self.values{idx} ; postV];
   else
      times = self.times{idx};
      values = self.values{idx};
   end
   
   ind = (times>=window(i,1)) & (times<=window(i,2));
   windowedTimes{i,1} = times(ind);
   
   % Index to allow expansion to arbitrary trailing dimensions
   idx = repmat({':'},1,numel(dim));
   windowedValues{i,1} = values(ind,idx{:});
end
self.times = windowedTimes;
self.values = windowedValues;
