% Set the offset property. Works for array object input, where
% offset must either be
%   scalar applied to all elements of the object array
%   {nObjs x 1} cell vector containing offsets for each element of
%       the object array
%
% SEE ALSO
% offset, applyOffset

function self = setOffset(self,offset)

n = numel(self);

if n == 1
   % single or multiple offsets
   if ~isnumeric(offset)
      error('Process:setOffset:InputFormat',...
         'Offset for a scalar process must be a numeric [nWin x 1] array.');
   end
   self.offset = offset;
else
   if isscalar(offset) && isnumeric(offset)
      % single offset or offsets, same for each process
      set(self,'offset',offset);
   elseif isvector(offset)
      % Different offset for each process
      offset = checkOffset(num2cell(offset),n);
      [self.offset] = deal(offset{:});
   elseif iscell(offset)
      % Different offset for each process
      offset = checkOffset(offset,n);
      [self.offset] = deal(offset{:});
   else
      error('Process:setOffset:InputFormat','Bad offset');
   end
end
