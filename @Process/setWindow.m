% Set the window property. Works for array object input, where
% window must either be
%   [1 x 2] vector applied to all elements of the object array
%   {nObjs x 1} cell vector containing windows for each element of
%       the object array
%
% SEE ALSO
% window, applyWindow

function self = setWindow(self,window)

n = numel(self);

if n == 1
   % single or multiple windows
   if ~isnumeric(window)
      if (numel(window)==1) && all([1 2]==size(window{1}))
         window = window{1};
      else
         error('Process:setWindow:InputFormat',...
            'Window for a scalar process must be a numeric [nWin x 2] array.');
      end
   end
   self.window = window;
else
   if isnumeric(window)
      % Single window or windows, same for each process
      set(self,'window',window);
   elseif iscell(window)
      % Different windows for each process
      window = checkWindow(window,n);
      [self.window] = deal(window{:});
   else
      error('Process:setWindow:InputFormat',...
         'Window badly formatted.');
   end
end
