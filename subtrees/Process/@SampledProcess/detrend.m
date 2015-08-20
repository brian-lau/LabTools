% Subtract mean

function self = detrend(self)

for i = 1:numel(self)
   %-- Add link to function queue ----------
   if ~self(i).running_ || ~self(i).deferredEval
      addToQueue(self(i));
      if self(i).deferredEval
         continue;
      end
   end
   %----------------------------------------

   for j = 1:size(self(i).window,1)
      self(i).values{j} = bsxfun(@minus,self(i).values{j},...
         nanmean(self(i).values{j}));
   end
end
