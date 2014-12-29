function proc = extract(self,request,flag)

if nargin == 2
   flag = 'label';
end
% FIXME, for object array
% FIXME, handle multiple returns???

proc = cell(size(self));
for i = 1:numel(self)
   switch lower(flag)
      case 'label'
         ind = cellfun(@(x) sum(strcmpi(x,request))>0,self(i).labels);
      case 'datatype'
         ind = cellfun(@(x) sum(strcmpi(class(x),request))>0,self(i).data);
   end
   if any(ind)
      proc{i} = self(i).data(ind);
   end
end
