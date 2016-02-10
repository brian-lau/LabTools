% Offset times,

function applyOffset(self,offset)

for i = 1:numel(offset)
   if offset(i) ~= 0
      self.times{i,1} = self.times{i,1} + offset(i);
   end
end