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

      temp = self.values{i,j};
      [temp.tStart] = list([temp.tStart] + offset(i));
      [temp.tEnd] = list([temp.tEnd] + offset(i));
      
%       for k = 1:numel(self.values{i,j})
%          self.values{i,j}(k).tStart = self.values{i,j}(k).tStart + offset(i);
%          self.values{i,j}(k).tEnd = self.values{i,j}(k).tEnd + offset(i);
%       end
   end
end