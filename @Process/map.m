% MAP - Pass Process values through function
%
%     map(Process,func,varargin)
%     Process.map(func,varargin)
%
%     Apply an function (passed in as a handle) to values, with the restriction 
%     that the function must return an output of the same input dimensionality.
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% INPUTS
%     func - function handle, required
%     B    - cell array, optional
%            Additional input to cellfun, number of elements must match the
%            number of windows
%
% OUTPUTS
%     obj - Process
%
% EXAMPLES
%     s = SampledProcess(randn(10,3));
%     plot(s);
%
%     % rectify
%     s.map(@(x) abs(x));
%     plot(s);
%
%     % Teager-Kaiser energy operator
%     s.reset();
%     tkeo = @(x) x.^2 - circshift(x,1).*circshift(x,-1);
%     s.map(@(x) tkeo(x));
%     plot(s);
%
%     % Divide each channel by different number
%     s.reset();
%     s.map(@(x) bsxfun(@rdivide,x,[1 2 3]));
%     plot(s);
%
%     % Using a function that does not maintain dimensionality will error
%     s.map(@(x) sum(x));

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process

% TODO
% o pass varargin through to func
% o allow time range?
function self = map(self,func,varargin)

p = inputParser;
p.KeepUnmatched = true;
addRequired(p,'func',@(x) isa(x,'function_handle'));
parse(p,func,varargin{:});

for i = 1:numel(self)
   %-- Add link to function queue ----------
   if isQueueable(self(i))
      addToQueue(self(i),func);
      if self(i).deferredEval
         continue;
      end
   end
   %----------------------------------------

   if isfield(p.Unmatched,'B')
      values = cellfun(func,self(i).values,p.Unmatched.B,'uni',false);
   else
      values = cellfun(func,self(i).values,'uni',false);
   end
   
   % Check dimensions
   match = cellfun(@(x,y) size(x) == size(y),self(i).values,values,'uni',false);
   if any(~cat(1,match{:}))
      error('Process:map:InputFormat','func must output same size');
   else
      self(i).values = values;
   end
end
