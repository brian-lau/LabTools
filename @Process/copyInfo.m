function info = copyInfo(self)
if isempty(self.info)
   info = containers.Map('KeyType','char','ValueType','any');
else
   info = containers.Map(self.info.keys,self.info.values);
end
