% Check whether dictionary contains value
%
% OUTPUT
% bool - boolean indicating whether value exists in map
% keys - corresponding cell array of keys for which bool is true
%
% It is possible to restrict to keys by passing in additional args
% mapHasValue(value,'keys',{cell array of keys})
%
% SEE ALSO
% mapfun

% TODO
%   o checking for cell array input?

function [bool,keys] = mapHasValue(m,value,varargin)

import map.*

if iscell(m)
   [temp,keys] = mapfun(@(x,y) isequal(x,y),m,{value},varargin{:},'UniformOutput',true);   
else
   [temp,keys] = mapfun(@(x,y) isequal(x,y),m,{value},varargin{:},'UniformOutput',false);
end

bool = cellfun(@(x) any(x),temp);
if nargout == 2
   for i = 1:numel(temp)
      keys{i} = keys{i}(logical(temp{i}));
   end
end

