function cp = countingProcess(self)
% Counting process representation
if any(isnan(self.window))
   cp = [NaN NaN];
else
   %window = self.window;
   %times = getTimes(self,window);
   times = times{1};
   count = cumsum(ones(size(times)));
   tStart = max(-inf,unique(min(times)));
   cp = [[tStart;times] , [0;count]];
end

