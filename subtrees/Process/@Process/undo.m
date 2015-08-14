function self = undo(self,n)

if nargin < 2
   n = 1;
end

for i = 1:numel(self)
   N = size(self(i).queue,1);
   if n > N
      n = 0;
   else
      n = N - n;
   end
   reset(self(i),n);
end