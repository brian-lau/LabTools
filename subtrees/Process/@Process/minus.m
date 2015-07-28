% Overloaded subtraction (minus, -)

function minus(x,y)

if isa(x,'Process') && isa(y,'Process')
   % TODO not done yet
   % should merge the objects?
elseif isa(x,'Process') && isnumeric(y)
   if isscalar(y)
      [x.offset] = deal(-y);
   else
      [x.offset] = list(-y);
   end
elseif isa(y,'Process') && isnumeric(x)
   if isscalar(y)
      [y.offset] = deal(-x);
   else
      [y.offset] = list(-x);
   end
else
   error('Minus not defined for inputs');
end
