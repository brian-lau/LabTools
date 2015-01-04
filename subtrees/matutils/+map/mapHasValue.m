% Check whether dictionary contains value
%
% OUTPUT
% bool - boolean indicating whether value exists in map
% keys - corresponding cell array of keys for which bool is true
%
% It is possible to restrict to keys by passing in additional args
% self.doesHashmapHaveValue(value,'keys',{cell array of keys})
%
% SEE ALSO
% mapfun

% TODO
%   o checking for cell array input?

function [bool,keys] = mapHasValue(map,value,varargin)

[temp,keys] = mapfun(@(x,y) isequal(x,y),map,{value},varargin{:});

bool = cellfun(@(x) any(x),temp);
if nargout == 2
   for i = 1:numel(temp)
      keys{i} = keys{i}(logical(temp{i}));
   end
end

