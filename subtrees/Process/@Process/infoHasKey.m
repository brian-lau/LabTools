% Boolean indicating whether Process info dictionary has key

function bool = infoHasKey(self,key)

bool = arrayfun(@(x,y) x.info.isKey(y),self,repmat({key},size(self)));

