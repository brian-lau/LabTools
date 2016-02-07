function q = checkQuality(self,quality)

assert(isnumeric(quality),'Process:quality:InputFormat',...
   'Must be numeric');

n = self.n;
if isempty(quality)
   quality = ones(1,n);
   q = quality;
elseif all(numel(quality)==n)
   q = quality(:)';
elseif numel(quality)==1
   q = repmat(quality,1,n);
else
   error('bad quality');
end
