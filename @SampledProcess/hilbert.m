function self = hilbert(self)

nObj = numel(self);
for i = 1:nObj
   nWin = numel(self(i).values);
   for j = 1:nWin
      self(i).values{j} = hilbert(self(i).values{j});
   end
end