% Make permanent current data transformations

function self = fix(self)

for i = 1:numel(self)
   self(i).Fs_ = self(i).Fs;
   self(i).quality_ = self(i).quality;
   self(i).selection_ = self(i).selection_(self(i).selection_);
   self(i).labels_ = self(i).labels;
   self(i).times_ = self.times;
   self(i).values_ = self(i).values;
   self(i).window_ = self(i).relWindow;
   self(i).cumulOffset = 0;
   self(i).offset_ = 0;
   self(i).offset = 0;
   self(i).set_n();
end
