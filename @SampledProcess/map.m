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
%addParamValue(p,'a',1,@isnumeric);
addParamValue(p,'fix',false,@islogical);
parse(p,func,varargin{:});

for i = 1:numel(self)
   values = cellfun(func,self(i).values,'uni',false);
   
   % Check dimensions
   match = cellfun(@(x,y) size(x) == size(y),self(i).values,values,'uni',false);
   if any(~cat(1,match{:}))
      error('SampledProcess:map:InputFormat','func must output same size');
   end
   
   if p.Results.fix
      self(i).values_ = func(self(i).values_);
      oldOffset = self(i).offset;
      applyWindow(self(i));
      self(i).offset = oldOffset;
   else
      self(i).values = values;
   end
end
