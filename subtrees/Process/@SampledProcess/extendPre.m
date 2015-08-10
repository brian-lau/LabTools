function [pre,preV] = extendPre(tStartOld,tStartNew,dt,dim)

if tStartNew < tStartOld
   pre = flipud(((tStartOld-dt):-dt:tStartNew)');
else
   pre = [];
end

if nargout == 2
   preV = nan([size(pre,1) row(dim)]);
end
