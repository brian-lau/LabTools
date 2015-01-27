% Set windows to earliest and latest event times
%
% SEE ALSO
% window, setWindow, applyWindow

function self = setInclusiveWindow(self)

for i = 1:numel(self)
   tempMin = cellfun(@(x) min(x(:,1)),self(i).times_,'uni',0);
   tempMin = min(vertcat(tempMin{:}));
   tempMax = cellfun(@(x) max(x(:)),self(i).times_,'uni',0);
   tempMax = max(vertcat(tempMax{:}));
   if isempty(tempMin) && isempty(tempMax)
      self(i).window = [NaN NaN];
   elseif tempMin == tempMax
      self(i).window = [tempMin tempMax+eps(tempMax)];
   else
      self(i).window = [tempMin tempMax];
   end
end
