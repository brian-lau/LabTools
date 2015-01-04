% Make a new containers.Map by copying selected key/value pairs
% from another
% copyKeys must be cell array of valid keys, 
% newKeys must have the same size as copyKeys
function newMap = copyMap(m,copyKeys,newKeys)

if nargin < 2
   copyKeys = m.keys;
end

if nargin < 3
   newKeys = copyKeys;
else
   if numel(copyKeys) ~= numel(newKeys)
      error('# of newKeys must match # requested in copyKeys');
   end
end

vals = m.values(copyKeys);
newMap = containers.Map(newKeys,vals);
