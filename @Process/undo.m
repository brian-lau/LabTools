function self = undo(self,m)

if nargin < 2
   m = 1;
end

for i = 1:numel(self)
   N = size(self(i).queue,1);
   if m > N
      n = 0;
   else
      n = N - m;
   end
   reset(self(i),n);
end