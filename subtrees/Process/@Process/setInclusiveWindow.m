% Set a window = [tStart tEnd]
%
% SEE ALSO
% window, setWindow, applyWindow
function self = setInclusiveWindow(self)

for i = 1:numel(self)
   self(i).window = [self(i).tStart self(i).tEnd];
end
