% Set a window = [tStart tEnd]
%
% SEE ALSO
% window, setWindow, applyWindow
function self = setInclusiveWindow(self)

for i = 1:numel(self)
   %-- Add link to function chain ----------
   if ~self(i).running_
      addLink(self(i));
      if self(i).lazyEval
         continue;
      end
   end
   %----------------------------------------
   
   self(i).window = [self(i).tStart self(i).tEnd];
end
