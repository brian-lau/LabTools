function discardBeforeStart(self)

for i = 1:numel(self.times_)
   ind = self.times_{i} < self.tStart;
   if any(ind)
      self.times_{i}(ind) = [];
      self.values_{i}(ind,self.trailingInd_{:}) = [];
   end
end
