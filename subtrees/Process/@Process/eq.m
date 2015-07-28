function bool = eq(x,y)
% Equality (==, isequal)
% Window-dependent properties are not used for comparison
%
% TODO
% check units ?
% maybe a 'strict' flag to compare window-dependent properties?
% handle case where both inputs are a vector?
if isa(x,'PointProcess') && isa(y,'PointProcess')
   % Handle case where one input is a vector
   nX = numel(x);
   nY = numel(y);
   if nX < nY
      if nX ~= 1
         error('At least one argument must have numel==1');
      else % y is a vector
         for i = 1:nY
            bool(i) = x == y(i);
         end
         return;
      end
   elseif nY < nX
      if nY ~= 1
         error('At least one argument must have numel==1');
      else % x is a vector
         for i = 1:nX
            bool(i) = y == x(i);
         end
         return;
      end
   end
   
   if x.info ~= y.info
      bool = false;
      return;
   elseif numel(x.times_) ~= numel(y.times_)
      bool = false;
      return;
   elseif any(x.times_ ~= y.times_)
      bool = false;
      return;
      %elseif any(x.map ~= y.map)
      %   bool = false;
      %   return;
   elseif x.tStart ~= y.tStart
      bool = false;
      return;
   elseif x.tEnd ~= y.tEnd
      bool = false;
      return;
   else
      bool = true;
   end
else
   error('Eq is not defined for inputs');
end