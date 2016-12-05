function bool = hasLabel(self,label)

n = numel(self);
bool = false(n,1);
for i = 1:n
   bool(i) = any(self(i).labels==label);
end