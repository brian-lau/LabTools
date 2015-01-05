% Overloaded subtraction (minus, -)

function minus(x,y)

if isa(x,'PointProcess') && isa(y,'PointProcess')
   % not done yet
   % should delete the common times from object
elseif isa(x,'PointProcess') && isnumeric(y)
   if numel(x) > 1
      [x.offset] = deal(list(-y));
   else
      [x.offset] = deal(-y);
   end
elseif isa(y,'PointProcess') && isnumeric(x)
   if numel(y) > 1
      [y.offset] = deal(list(-x));
   else
      [y.offset] = deal(-x);
   end
else
   error('Minus not defined for inputs');
end
