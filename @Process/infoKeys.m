% Return array of keys in INFO dictionary
%
% If flatBool is true (default false), the returned cell array
% will be collapsed across all Process elements passed in

function keys = infoKeys(self,flatBool)

if nargin < 2
   flatBool = false;
end

keys = arrayfun(@(x) x.info.keys,self,'uniformoutput',false);
if flatBool
   keys = cell.flatten(keys);
end
