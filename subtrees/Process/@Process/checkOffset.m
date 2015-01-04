function validOffset = checkOffset(offset,n)
% Validate offset, and replicate if necessary
%
% % single offset
% [offset]
%
% % one offset for each of n elements
% [offset(1)
%  offset(2)
%  offset(n)
%    ]
%
% % aribitrary offsets for each of n elements
% {
%   [offset(1,1)   [offset(1,2)   [start(1,n) end(1,n)]
%    offset(2,1)]   offset(2,2)]   start(2,2) end(2,2)]
%  }
%
% For example, to use the same set of windows for n elements,
% checkWindow({[-6 0;0 6;-6 6]},n)
if nargin == 1
   n = 1;
end

if iscell(offset)
   % Same offsets for each element
   if numel(offset) == 1
      offset(1:n) = offset;
   end
   % Different offsets for each element
   if numel(offset) == n
      for i = 1:n
         validOffset{1,i} = Process.checkOffset(offset{i},length(offset{i}));
      end
   else
      error('process:checkOffset:InputFormat',...
         'Cell array offset must be {[nx1]} or [nObjs x 1]');
   end
else
   if numel(offset) == 1
      if n > 1
         offset = repmat(offset,n,1);
      end
   end
   if numel(offset) ~= n
      error('process:checkOffset:InputFormat',...
         'Incorrect number of offsets.');
   end
   validOffset = offset(:);
end