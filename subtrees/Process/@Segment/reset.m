function self = reset(self)

for i = 1:numel(self.processes)
   self.processes{i}.reset();
end
self.window = self.window_;
self.offset = self.offset_;