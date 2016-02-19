function self = applySubset(self)

if ~any(self.selection_)
   self.times = cellfun(@(x) x(:,false),self.times,'uni',0);
end
self.values = cellfun(@(x) x(:,self.selection_),self.values,'uni',0);
self.set_n();
self.labels = self.labels(self.selection_);
self.quality = self.quality(self.selection_);
