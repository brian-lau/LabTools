function self = detrend(self)

for i = 1:numel(self)
   for j = 1:size(self(i).window,1)
      self(i).values{j} = bsxfun(@minus,self(i).values{j},...
         nanmean(self(i).values{j}));
   end
end
