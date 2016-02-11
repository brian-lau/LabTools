% Offset times,
function applyOffset(self,offset)

for i = 1:numel(offset)
   for j = 1:self.n
      if offset(i) ~= 0
         self.times{i,j} = self.times{i,j} + offset(i);
      end
   end
end
