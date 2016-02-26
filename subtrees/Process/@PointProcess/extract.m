% Extract times & values
function [s,labels] = extract(self,reqLabels)

s(numel(self),1) = struct('times',[],'values',[]);
labels = cell(numel(self),1);
for i = 1:numel(self)
   if nargin < 2
      labels{i,1} = self(i).labels;
      ind = 1:self(i).n;
   else
      [labels{i,1},~,ind] = intersect(reqLabels,self(i).labels,'stable');
   end
   
   if any(ind)
      if size(self(i).window,1) == 1
         s(i).times = self(i).times(ind);
         s(i).values = self(i).values(ind);
      else
         s(i).times = cellfun(@(x) x,self(i).times(:,ind),'uni',0);
         s(i).values = cellfun(@(x) x,self(i).values(:,ind),'uni',0);
      end
   end
end
