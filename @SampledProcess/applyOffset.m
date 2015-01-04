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

for i = 1:numel(offset)
   self.times{i,1} = self.times{i,1} + offset(i);
end
