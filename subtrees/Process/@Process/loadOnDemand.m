function loadOnDemand(self,varargin)

if ~self.isLoaded
   disp('loading');
   window = self.window;
   for i = 1:size(window,1)
      ind = (self.times_{1}>=window(i,1)) & (self.times_{1}<=window(i,2));
      values{i,1} = self.values_{1}(ind,:);
   end
   self.values = values;
   self.isLoaded = true;
   applyWindow(self);
   applyOffset(self,self.offset);
end
