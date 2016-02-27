function self = applySubset(self,subsetOriginal)

if nargin < 2
   subsetOriginal = false;
end

if ~any(self.selection_)
   % There are no channels left, create a zero-dimensional vector
   self.times = cellfun(@(x) x(:,false),self.times,'uni',0);
end

self.values = cellfun(@(x) x(:,:,self.selection_),self.values,'uni',0);
self.set_n();
self.labels = self.labels(self.selection_);
self.quality = self.quality(self.selection_);

if subsetOriginal
   self.labels_ = self.labels;
   self.quality_ = self.quality;
   
   if ~any(self.selection_)
      % There are no channels left, create a zero-dimensional vector
      self.times_ = cellfun(@(x) x(:,false),self.times_,'uni',0);
   end

   self.values_ = cellfun(@(x) x(:,:,self.selection_),self.values_,'uni',0);
   self.selection_ = self.selection_(self.selection_);
end