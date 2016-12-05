function self = applySubset(self,subsetOriginal)

if nargin < 2
   subsetOriginal = false;
end

self.times = self.times(:,self.selection_);
self.set_n();
self.values = self.values(:,self.selection_);
self.labels = self.labels(self.selection_);
self.quality = self.quality(self.selection_);

if subsetOriginal
   self.labels_ = self.labels;
   self.quality_ = self.quality;
   
   self.times_ = self.times_(:,self.selection_);

   self.values_ = self.values_(:,self.selection_);
   self.selection_ = self.selection_(self.selection_);
end