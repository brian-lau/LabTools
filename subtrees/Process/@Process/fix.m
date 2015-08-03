function self = fix(self)

for i = 1:numel(self)
   self(i).values_ = self(i).values;
   self(i).times_ = self.times;
   self(i).window_ = self(i).window + self(i).cumulOffset;
   self(i).cumulOffset = 0;
   self(i).offset_ = 0;
   self(i).offset = 0;
end
