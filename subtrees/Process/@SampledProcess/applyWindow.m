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

nWindow = size(self.window,1);
assert(nWindow==numel(self.values),'monkey!');

window = self.window;
windowedTimes = cell(nWindow,1);
windowedValues = cell(nWindow,1);
for i = 1:nWindow
   % NaN-pad when window extends beyond process. This extension is
   % done to the nearest sample that fits in the window.
   minWin = min(window(i,1));
   maxWin = max(window(i,2));
   tStart = min(self.times{i});
   tEnd = max(self.times{i});
   dim = size(self.values{i});
   dim = dim(2:end); % leading dim is always time
   if (minWin<tStart) && (maxWin>tEnd)
      [pre,preV] = self.extendPre(tStart,minWin,1/self.Fs,dim);
      [post,postV] = self.extendPost(tEnd,maxWin,1/self.Fs,dim);
      times = [pre ; self.times{i} ; post];
      values = [preV ; self.values{i} ; postV];
   elseif (minWin<tStart) && (maxWin<=tEnd)
      [pre,preV] = self.extendPre(tStart,minWin,1/self.Fs,dim);
      times = [pre ; self.times{i}];
      values = [preV ; self.values{i}];
   elseif (minWin>=tStart) && (maxWin>tEnd)
      [post,postV] = self.extendPost(tEnd,maxWin,1/self.Fs,dim);
      times = [self.times{i} ; post];
      values = [self.values{i} ; postV];
   else
      times = self.times{i};
      values = self.values{i};
   end
   
   ind = (times>=window(i,1)) & (times<=window(i,2));
   windowedTimes{i,1} = times(ind);
   
   % Index to allow expansion to arbitrary trailing dimensions
   idx = repmat({':'},1,numel(dim));
   windowedValues{i,1} = values(ind,idx{:});
end
self.times = windowedTimes;
self.values = windowedValues;
