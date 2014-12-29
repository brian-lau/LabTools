function post = extendPost(tEndOld,tEndNew,dt)
if tEndNew > tEndOld
   post = ((tEndOld+dt):dt:tEndNew)';
else
   post = [];
end
