% Subtract mean

function self = detrend(self)

for i = 1:numel(self)
   %-- Add link to function queue ----------
   if ~self(i).running_
      addToQueue(self(i));
      if self(i).lazyEval
         continue;
      end
   end
   %----------------------------------------

   for j = 1:size(self(i).window,1)
      self(i).values{j} = bsxfun(@minus,self(i).values{j},...
         nanmean(self(i).values{j}));
   end
end
