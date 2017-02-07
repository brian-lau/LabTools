% Window event times, setting
%     times
%     values

% TODO
%   o Round windows to dt to avoid surprises due to numerical error?

function applyWindow(self)

if isempty(self.times)
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
   if isempty(times)
      continue;
   else
      tStart = times(1);
      tEnd = times(end);
   end
   dim = size(values);
   dim = dim(2:end); % leading dim is always time

   % NaN-pad when window extends beyond process. This extension is
   % done to the nearest sample that fits in the window.
   [preT,preV] = extendPre(min(tStart,maxWin+self.dt),minWin,1/self.Fs,dim);
   [postT,postV] = extendPost(tEnd,maxWin,1/self.Fs,dim);

   ind = (times>=window(i,1)) & (times<=window(i,2));
   if ~isempty(preT) && ~isempty(postT)
      windowedTimes{i,1} = [preT ; times(ind) ; postT];
      windowedValues{i,1} = [preV ; values(ind,:) ; postV];
   elseif isempty(preT) && ~isempty(postT)
      if sum(ind) ~= numel(ind)
         windowedTimes{i,1} = [times(ind) ; postT];
         windowedValues{i,1} = [values(ind,:) ; postV];
      else
         windowedTimes{i,1} = [times ; postT];
         windowedValues{i,1} = [values ; postV];
      end
   elseif ~isempty(preT) && isempty(postT)
      if sum(ind) ~= numel(ind)
         windowedTimes{i,1} = [preT ; times(ind)];
         windowedValues{i,1} = [preV ; values(ind,:)];
      else
         windowedTimes{i,1} = [preT ; times];
         windowedValues{i,1} = [preV ; values];
      end
   else
      if all(ind)
         windowedTimes{i,1} = times;
         windowedValues{i,1} = values;
      else
         windowedTimes{i,1} = times(ind);
         windowedValues{i,1} = values(ind,:);
      end
   end
end

self.times = windowedTimes;
self.values = windowedValues;
