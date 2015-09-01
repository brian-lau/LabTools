% Overloaded addition (plus, +)
% When one of (x,y) is a PointProcess, and the other a scalar, +
% will change the offset according to the scalar.
% When x & y are both PointProcesses, they will be merged

function plus(x,y)

if isa(x,'Process') && isa(y,'Process')
   % TODO not done yet
   % should merge the objects?
elseif isa(x,'Process') && isnumeric(y)
   if isscalar(y)
      [x.offset] = deal(y);
   else
      [x.offset] = list(y);
   end
elseif isa(y,'Process') && isnumeric(x)
   if isscalar(y)
      [y.offset] = deal(x);
   else
      [y.offset] = list(x);
   end
else
   error('Plus not defined for inputs');
end

