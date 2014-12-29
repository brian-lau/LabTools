% Interevent interval representation
function iei = intervals(self)
iei = cellfun(@diff,self.times,'UniformOutput',false);

