function self = sync(self,event,varargin)

% Segment is scalar
% same event for each process
% different event for each process (where each process is scalar)
% different event for each process (where each process could be vector)

% Segment is vector

for i = 1:numel(self)
   if numel(event) == 1
      cellfun(@(x) x.sync(event,varargin{:}),self(i).processes,'uni',0);
   elseif numel(event) == numel(self(i).processes)
      cellfun(@(x,y) x.sync(y,varargin{:}),self(i).processes,...
         mat2cell(event,1,ones(1,numel(self(i).processes))),'uni',0);
   else
      error('incorrect number of events');
   end
end
