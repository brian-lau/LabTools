% Offset times,

function applyOffset(self,undo)

if nargin == 1
   undo = false;
end

if undo
   offset = -self.offset;
else
   offset = self.offset;
end

nTimes = size(self.times,2);
for i = 1:numel(offset)
   for j = 1:nTimes
      self.times{i,j} = self.times{i,j} + offset(i);

      % Adjust times stored in Events
      temp = self.values{i,j};

      if ~isempty(temp)
         for k = 1:numel(temp)
            temp(k).tStart = temp(k).tStart + offset(i);
            temp(k).tEnd = temp(k).tEnd + offset(i);
         end
      end
   end
end