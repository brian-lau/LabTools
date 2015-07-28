% Overloaded subtraction (minus, -)

function minus(x,y)

if isa(x,'PointProcess') && isa(y,'PointProcess')
   % not done yet
   % should delete the common times from object
elseif isa(x,'PointProcess') && isnumeric(y)
   if isscalar(y)
      [x.offset] = deal(-y);
   else
      [x.offset] = list(-y);
   end
elseif isa(y,'PointProcess') && isnumeric(x)
   if isscalar(y)
      [y.offset] = deal(-x);
   else
      [y.offset] = list(-x);
   end
else
   error('Minus not defined for inputs');
end
