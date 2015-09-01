function [post,postV] = extendPost(tEndOld,tEndNew,dt,dim)

if tEndNew > tEndOld
   post = ((tEndOld+dt):dt:tEndNew)';
else
   post = [];
end

if nargout == 2
   postV = nan([size(post,1) row(dim)]);
end

% function post = extendPost(tEndOld,tEndNew,dt)
% 
% if tEndNew > tEndOld
%    post = ((tEndOld+dt):dt:tEndNew)';
% else
%    post = [];
% end
