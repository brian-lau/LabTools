function bool = infoHasKey(self,key)
% Boolean for whether INFO dictionary has key
bool = arrayfun(@(x,y) x.info.isKey(y),self,repmat({key},size(self)));

