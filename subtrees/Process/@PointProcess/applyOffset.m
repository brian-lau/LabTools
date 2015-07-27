% Offset times,
function applyOffset(self,offset)

nTimes = size(self.times,2);
for i = 1:numel(offset)
   for j = 1:nTimes
      self.times{i,j} = self.times{i,j} + offset(i);
   end
end
