function self = insert(self,times,values,labels)
% Insert times
% Note that this adjusts tStart and tEnd to include all times.
% Note that if there is already an offset, new times are added to
% original times (w/out offset), and then rewindowed and offset
%
% times  - either an array of event times to insert
%          or a containers.Map object, with keys of type 'double'
%          defining the event times to add
% values - values associated with event times to insert
% labels - strings defining which process to insert to
%
% SEE ALSO
% remove

% TODO
% perhaps additional flags to overwrite? no, replaceTimes
if nargin < 3
   error('PointProcess:insert:InputFormat',...
      'There must be values for each inserted time');
end
if numel(times) ~= numel(values)
   error('PointProcess:insert:InputFormat',...
      'There must be values for each inserted time');
end
for i = 1:numel(self)
   if nargin < 4
      % Insert same times & values from all
      labels = self(i).labels;
   end
   
   indL = find(ismember(self(i).labels,labels));
   if any(indL)
      % Index of redundant times
      indR = cellfun(@(x) ismember(times,x),self(i).times_(indL),'uni',0);
      for j = 1:numel(indL)
         times2Insert{j} = times;
         values2Insert{j} = values;
         if any(indR{j})
            fprintf('%g/%g redundant event times ignored for %s.\n',...
               sum(indR{j}),length(indR{j}),self(i).labels{indL(j)});
            times2Insert{j}(indR{j}) = [];
            values2Insert{j}(indR{j}) = [];
         end
         
         if any(times2Insert{j})
            % Check that we can concatenate values
            % Values must match type of present values for contcatenation
            if isequal(class(values2Insert{j}),class(self.values_{indL(j)}))
               % Merge
               [self(i).times_{indL(j)},I] = ...
                  sort([self(i).times_{indL(j)} ; times2Insert{j}(:)]);
               temp = [self(i).values_{indL(j)} ; values2Insert{j}(:)];
               %temp = self(i).values_{indL(j)};
               %temp((end+1):(end+1+numel(values2Insert{j}))) = ...
               %   values2Insert{j};
               self(i).values_{indL(j)} = temp(I);
               inserted(j) = true;
            else
               inserted(j) = false;
               warning('PointProcess:insert:InputFormat',...
                  ['times not added for ' self(i).labels{indL} ...
                  ' because value type does not match']);
            end
         else
            inserted(j) = false;
         end
      end
      
      if any(inserted)
         timesInserted = cell2mat(times2Insert(inserted));
         oldWindow = self(i).window;
         % Reset properties that depend on event times
         if min(timesInserted) < self(i).tStart
            self(i).tStart = min(timesInserted);
         end
         if max(timesInserted) > self(i).tEnd
            self(i).tEnd = max(timesInserted);
         end
         oldOffset = self(i).offset;
         self(i).offset = 'windowIsReset';
         self(i).window = oldWindow;
         applyWindow(self(i));
         self(i).offset = oldOffset;
      end
   end
end
