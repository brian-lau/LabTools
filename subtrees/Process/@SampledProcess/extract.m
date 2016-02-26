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
         s(i).times = self(i).times{1};
         if numel(ind) == self(i).n
            s(i).values = self(i).values{1};
         else
            s(i).values = self(i).values{1}(:,ind);
         end
      else
         s(i).times = cellfun(@(x) x,self(i).times,'uni',0);
         s(i).values = cellfun(@(x) x(:,ind),self(i).values,'uni',0);
      end
   end
end
