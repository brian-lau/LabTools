function self = resample(self,newFs)

assert(isnumeric(newFs)&&isscalar(newFs)&&(newFs>0),...
   'PointProcess:resample:InputValue',...
   'New sampling frequency must be a numeric scalar.');

for i = 1:numel(self)
   %-- Add link to function queue ----------
   if isQueueable(self(i))
      addToQueue(self(i),newFs);
      if self(i).deferredEval
         continue;
      end
   end
   %----------------------------------------
   
   if self(i).Fs == newFs
      continue;
   end
   
   times = cellfun(@(x) roundToProcessResolution(self(i),x,1/newFs),self(i).times,'uni',0);
   
   self(i).times = times;
   self(i).Fs = newFs;
end