% Extend a time vector if new tStart preceeds old tStart

function [preT,preV] = extendPre(tStartOld,tStartNew,dt,dim)

if tStartNew < tStartOld
   preT = flipud(((tStartOld-dt):-dt:tStartNew)');
else
   preT = [];
end

if nargout == 2
   preV = nan([size(preT,1) row(dim)]);
end
