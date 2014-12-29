function discardAfterEnd(self)
ind = self.times_ > self.tEnd;
if any(ind)
   self.times_(ind) = [];
   self.values_(ind,:) = [];
end
