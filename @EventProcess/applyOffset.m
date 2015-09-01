% Offset times,

function applyOffset(self,offset)

nTimes = size(self.times,2);
for i = 1:numel(offset)
   for j = 1:nTimes
      self.times{i,j} = self.times{i,j} + offset(i);

      % Adjust times stored in Events
      temp = self.values{i,j};
      for k = 1:numel(temp)
         temp(k).tStart = self.times{i,j}(k,1);
         temp(k).tEnd = self.times{i,j}(k,2);
      end
      self.values{i,j} = temp;
   end
end