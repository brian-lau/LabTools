
function obj = new(self)

obj = copy(self);
nObj = numel(obj);
for i = 1:nObj
   obj(i).info = copyInfo(obj(i));
   obj(i).labels = copy(obj(i).labels);
end
