function l = checkLabels(self,labels)

n = self.n;
if isempty(labels)
   l = arrayfun(@(x) metadata.Label('name',['id' num2str(x)]),1:n,'uni',0);
   l = cat(2,l{:});
elseif iscell(labels)
   assert(numel(labels)==n,'Process:labels:InputFormat',...
      '# labels does not match # of signals');
   if ~all(cellfun(@(x) isa(x,'metadata.Label'),labels))
      l = cellfun(@(x) metadata.Label('name',x),labels,'uni',0);
      l = cat(2,l{:});
   else
      l = cat(2,labels{:});
   end
elseif (n==1)
   if isa(labels,'metadata.Label')
      l = labels;
   else
      l = metadata.Label('name',labels);
   end
elseif n == numel(labels)
   if isa(labels,'metadata.Label')
      l = labels;
   else
      error('bad format');
   end
else
   error('Process:labels:InputType','Incompatible label type');
end
