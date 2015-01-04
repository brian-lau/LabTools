function self = remove(self,times,labels)
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
      indT = cellfun(@(x) ismember(x,times),self(i).times_(indL),'uni',0);
      for j = 1:numel(indL)
         if any(indT{j})
            self(i).times_{indL(j)}(indT{j}) = [];
            self(i).values_{indL(j)}(indT{j}) = [];
         end
      end
      if any(cellfun(@(x) any(x),indT))
         % Reset properties that depend on event times
         oldOffset = self(i).offset;
         self(i).offset = 'windowIsReset';
         applyWindow(self(i));
         self(i).offset = oldOffset;
      end
   end
end