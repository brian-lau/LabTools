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

% TODO, mask by tStart/tEnd
%   o check values dimensions?
%   o multiple windows??

function self = insert(self,times,values,labels)

if nargin < 3
   error('PointProcess:insert:InputFormat',...
      'There must be values for each inserted time');
end
if numel(times) ~= numel(values)
   error('PointProcess:insert:InputFormat',...
      'Number of times and values must match');
end
for i = 1:numel(self)
   if nargin < 4
      % Insert same times & values from all
      labels = self(i).labels;
   end
   
   indL = find(ismember(self(i).labels,labels));
   if any(indL)
      for j = 1:numel(indL)
         times2Insert = self(i).roundToProcessResolution(times);
         values2Insert = values;
         
         if ~isempty(times2Insert)
            % Check that we can concatenate values
            % Values must match type of present values for contcatenation
            if isequal(class(values2Insert),class(self(i).values_{indL(j)})) || ...
               (isa(values2Insert,'matlab.mixin.Heterogeneous') && isa(self(i).values{indL(j)},'matlab.mixin.Heterogeneous'))
               % Merge & sort
               [self(i).times{indL(j)},I] = ...
                  sort([self(i).times{indL(j)} ; times2Insert(:)]);
               temp = [self(i).values{indL(j)} ; values2Insert(:)];
               self(i).values{indL(j)} = temp(I);
            else
               warning('PointProcess:insert:InputFormat',...
                  ['times not added for ' self(i).labels{indL} ...
                  ' because value type does not match']);
            end
         end
      end
   end
end
