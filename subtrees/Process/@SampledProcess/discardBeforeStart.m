function discardBeforeStart(self)

ind = self.times_ < self.tStart;
if any(ind)
   self.times_(ind) = [];
   self.values_(ind,:) = [];
end
