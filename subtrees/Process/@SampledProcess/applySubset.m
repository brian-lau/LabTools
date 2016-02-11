function self = applySubset(self)

self.values = cellfun(@(x) x(:,self.selection_),self.values,'uni',0);
self.set_n();
self.labels = self.labels(self.selection_);
self.quality = self.quality(self.selection_);
