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
      
      if offset(i) > 0
         temp = num2cell([self.values{i,j}.tEnd] + offset(i));
         [self.values{i,j}.tEnd] = deal(temp{:});         
         temp = num2cell([self.values{i,j}.tStart] + offset(i));
         [self.values{i,j}.tStart] = deal(temp{:});
      else
         temp = num2cell([self.values{i,j}.tStart] + offset(i));
         [self.values{i,j}.tStart] = deal(temp{:});
         temp = num2cell([self.values{i,j}.tEnd] + offset(i));
         [self.values{i,j}.tEnd] = deal(temp{:});         
      end
   end
end