function self = setOffset(self,offset)
% Set the offset property. Works for array object input, where
% offset must either be
%   scalar applied to all elements of the object array
%   {nObjs x 1} cell vector containing offsets for each element of
%       the object array
%
% SEE ALSO
% offset, applyOffset
n = numel(self);
if n == 1
   % single or multiple offsets
   if ~isnumeric(offset)
      error('process:setOffset:InputFormat',...
         'Offset for a scalar process must be a numeric [nWin x 1] array.');
   end
   self.offset = self.checkOffset(offset,size(self.window,1));
else
   if isscalar(offset) && isnumeric(offset)
      % single offset or offsets, same for each process
      offset = self.checkOffset(offset);
      [self.offset] = deal(offset);
   elseif isvector(offset)
      % Different offset for each process
      offset = self.checkOffset(num2cell(offset),n);
      [self.offset] = deal(offset{:});
   elseif iscell(offset)
      % Different offset for each process
      offset = self.checkWindow(offset,n);
      [self.offset] = deal(offset{:});
   else
      error('process:setOffset:InputFormat','Bad offset');
   end
end
