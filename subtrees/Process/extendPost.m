% Extend a time vector if new tEnd exceeds old tEnd

function [postT,postV] = extendPost(tEndOld,tEndNew,dt,dim)

if tEndNew > tEndOld
   postT = ((tEndOld+dt):dt:tEndNew)';
else
   postT = [];
end

if nargout == 2
   if isempty(postT)
      postV = [];
   else
      postV = nan([size(postT,1) row(dim)]);
   end
end
