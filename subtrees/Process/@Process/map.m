% The new method 'map' allows you to apply an function (passed in as a handle)
% to SampledProcess values, with the restriction that your function must return
% an output of the same dimensionality as its input.
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
% % Using a function that does not maintain dimensionality will error
% s.map(@(x) sum(x));
%
% % reset
% s.reset();
%
% % Teager-Kaiser energy operator (assumes column arrangement)
% tkeo = @(x) x.^2 - circshift(x,1).*circshift(x,-1);
% s.map(@(x) tkeo(x))

function self = map(self,func,varargin)

p = inputParser;
p.KeepUnmatched = true;
addRequired(p,'func',@(x) isa(x,'function_handle'));
parse(p,func,varargin{:});

for i = 1:numel(self)
   
   if ~self(i).running
      addLink(self(i),func);
      if self(i).lazy
         continue;
      end
   end
   
   values = cellfun(func,self(i).values,'uni',false);
   % Check dimensions
   match = cellfun(@(x,y) size(x) == size(y),self(i).values,values,'uni',false);
   if any(~cat(1,match{:}))
      error('SampledProcess:map:InputFormat','func must output same size');
   else
      self(i).values = values;
   end
end
