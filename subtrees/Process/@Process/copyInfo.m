% Copy Process info dictionary

function info = copyInfo(self)

if isempty(self.info)
   info = containers.Map('KeyType','char','ValueType','any');
else
   info = map.copyMap(self.info);
end
