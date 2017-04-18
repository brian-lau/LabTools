% Remove times and associated values
% Note that this does NOT change tStart or tEnd.
%
% times  - array of event times to remove
% labels - string, cell array of strings
%          indicating which process to remove times
%          from.
%          default = all
%
% SEE ALSO
% insert

% TODO
%   o 

function self = remove(self,times,labels)

if nargin < 2
   error('PointProcess:remove:InputFormat',...
      'You must provide times to remove.');
end
for i = 1:numel(self)
   if nargin < 3
      % Remove same times from all
      labels = self(i).labels;
   end
   indL = find(ismember(self(i).labels,labels));
   if any(indL)
      indT = cellfun(@(x) ismember(x(:,1),times),self(i).times(indL),'uni',0);
      for j = 1:numel(indL)
         if any(indT{j})
            self(i).times{indL(j)}(indT{j},:) = [];
            self(i).values{indL(j)}(indT{j}) = [];
         end
      end
   end
end