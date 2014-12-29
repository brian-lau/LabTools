function pre = extendPre(tStartOld,tStartNew,dt)
if tStartNew < tStartOld
   pre = flipud(((tStartOld-dt):-dt:tStartNew)');
else
   pre = [];
end
