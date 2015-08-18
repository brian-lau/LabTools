% Apply an function (passed in as a handle) values, with the restriction 
% that your function must return an output of the same input dimensionality.
%
% An example:
%
% s = SampledProcess(randn(10,3));
% plot(s);
%
% % rectify
% s.map(@(x) abs(x));
% plot(s);
%
% % Teager-Kaiser energy operator
% tkeo = @(x) x.^2 - circshift(x,1).*circshift(x,-1);
% s.map(@(x) tkeo(x))
%
% % Using a function that does not maintain dimensionality will error
% s.map(@(x) sum(x));
%

function self = map(self,func,varargin)

p = inputParser;
p.KeepUnmatched = true;
addRequired(p,'func',@(x) isa(x,'function_handle'));
parse(p,func,varargin{:});

for i = 1:numel(self)
   %-- Add link to function queue ----------
   if ~self(i).running_ || ~self(i).lazyEval
      addToQueue(self(i),func);
      if self(i).lazyEval
         continue;
      end
   end
   %----------------------------------------

   values = cellfun(func,self(i).values,'uni',false);
   % Check dimensions
   match = cellfun(@(x,y) size(x) == size(y),self(i).values,values,'uni',false);
   if any(~cat(1,match{:}))
      error('SampledProcess:map:InputFormat','func must output same size');
   else
      self(i).values = values;
   end
end
