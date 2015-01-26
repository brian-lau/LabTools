function self = sync(self,event,varargin)

for i = 1:numel(self)
   cellfun(@(x) x.sync(event,varargin{:}),self(i).processes,'uni',false);
end
