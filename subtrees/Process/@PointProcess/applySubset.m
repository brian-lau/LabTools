function self = applySubset(self)

self.times = self.times(:,self.selection_);
self.values = self.values(:,self.selection_);
self.labels = self.labels(self.selection_);
self.quality = self.quality(self.selection_);
