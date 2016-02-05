function bool = hasLabel(self,label)

n = numel(self);
bool = false(n,1);
for i = 1:n
   bool(i) = any(cellfun(@isequal,self(i).labels,repmat({label},1,numel(self(i).count))));
end