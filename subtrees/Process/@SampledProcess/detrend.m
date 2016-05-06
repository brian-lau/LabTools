% Subtract mean

function self = detrend(self,flag)

if nargin < 2
   flag = 'constant';
end

for i = 1:numel(self)
   %-- Add link to function queue ----------
   if isQueueable(self(i))
      addToQueue(self(i));
      if self(i).deferredEval
         continue;
      end
   end
   %----------------------------------------

   for j = 1:size(self(i).window,1)
      self(i).values{j} = detrend(self(i).values{j},flag);
   end
end
