% Validate window, and replicate if necessary
%
% % single window
% [start end]
%
% % one window for each of n elements
% [start(1,1) end(1,1)
%    start(2,1) end(2,1)
%    start(n,1) end(n,1)
%    ]
%
% % aribitrary windows for each of n elements
% {
%   [start(1,1) end(1,1)   [start(1,2) end(1,2)   [start(1,n) end(1,n)]
%    start(2,1) end(2,1)]   start(2,2) end(2,2)]
%  }
%
% For example, to use the same set of windows for n elements,
% checkWindow({[-6 0;0 6;-6 6]},n)
% checkWindow({[0 1;1 2] [2 3]},2)

function validWindow = checkWindow(window,n)

if nargin == 1
   n = 1;
end

if iscell(window)
   % Same windows for each element
   if numel(window) == 1
      window(1:n) = window;
   end
   % Different windows for each element
   if numel(window) == n
      for i = 1:n
         validWindow{1,i} = checkWindow(window{i},size(window{i},1));
      end
   else
      error('Process:checkWindow:InputFormat',...
         'Cell array window must be {[nx2]} or [nObjs x 2]');
   end
else
   assert((size(window,2)==2),'Process:checkWindow:InputFormat',...
      'Window must have two columns');
   if (n>1) && (size(window,1)==1)
      window = repmat(window,n,1);
   end
   if any(window(:,1)>window(:,2))
      error('Process:checkWindow:InputValue',...
         'First element of window must be less than second');
   end
   validWindow = window;
end
