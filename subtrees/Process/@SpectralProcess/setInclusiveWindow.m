% Set a window = [tStart tEnd]
%
% SEE ALSO
% window, setWindow, applyWindow
function self = setInclusiveWindow(self)

for i = 1:numel(self)
   %-- Add link to function queue ----------
   if isQueueable(self(i))
      addToQueue(self(i));
      if self(i).deferredEval
         continue;
      end
   end
   %----------------------------------------
   
   b = 0;%self(i).tBlock;
   self(i).window = [self(i).tStart self(i).tEnd-b];
end
