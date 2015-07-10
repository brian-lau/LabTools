function self = reset(self)

for i = 1:numel(self)
   cellfun(@(x) x.reset,self(i).processes,'uni',0);
   self(i).validSync = [];
end