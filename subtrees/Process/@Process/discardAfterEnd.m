function discardAfterEnd(self)

ind = cellfun(@(x) x(:,1)>self.tEnd,self.times_,'uni',0);
if any(cellfun(@(x) any(x(:)),ind))
   for i = 1:numel(self.times_)
      self.times_{i}(ind{i}) = [];
      self.values_{i}(ind{i},self.trailingInd_{:}) = [];
   end
end