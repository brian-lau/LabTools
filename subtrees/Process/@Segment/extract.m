function proc = extract(self,request,flag)

if nargin == 2
   flag = 'label';
end

proc = cell(size(self));
for i = 1:numel(self)
   switch lower(flag)
      case 'label'
         ind = cellfun(@(x) sum(strcmpi(x,request))>0,self(i).labels);
      case 'type'
         ind = cellfun(@(x) sum(strcmpi(class(x),request))>0,self(i).processes);
   end
   if ~any(ind)
      proc = {};
   else
      proc{i} = horzcat(self(i).processes{ind});
   end
end

if (numel(self)==1) && any(ind)
   proc = proc{1};
end