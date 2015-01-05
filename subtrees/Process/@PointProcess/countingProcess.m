% Counting process representation

function cp = countingProcess(self)

if any(isnan(self.window))
   cp = [NaN NaN];
else
   times = times{1};
   count = cumsum(ones(size(times)));
   tStart = max(-inf,unique(min(times)));
   cp = [[tStart;times] , [0;count]];
end

