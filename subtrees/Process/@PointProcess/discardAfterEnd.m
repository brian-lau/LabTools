function discardAfterEnd(self)
ind = cellfun(@(x) (x>self.tEnd),self.times_,'uni',0);
if any(cellfun(@any,ind))
   for i = 1:numel(self.times_)
      self.times_{i}(ind{i}) = [];
      self.values_{i}(ind{i}) = [];
   end
end