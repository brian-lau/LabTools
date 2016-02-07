function q = checkQuality(self,quality)

assert(isnumeric(quality),'Process:quality:InputFormat',...
   'Must be numeric');

n = self.n;
if isempty(quality)
   q = ones(1,n);   
elseif numel(quality)==n
   q = quality(:)';
elseif numel(quality)==1
   q = repmat(quality,1,n);
else
   error('bad quality');
end