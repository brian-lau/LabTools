% TODO
%   o edge padding
%   o handle nan padding (filter state?, replace nans?)
%   o different filtering methods (causal, etc.)

function self = filter(self,b,varargin)

p = inputParser;
p.KeepUnmatched = true;
addRequired(p,'b',@(x) isnumeric(x) || isa(x,'dfilt.dffir'));
addParameter(p,'a',1,@isnumeric);
addParameter(p,'compensateDelay',true,@islogical);
parse(p,b,varargin{:});

if isa(b,'dfilt.dffir')
   h = b;
   b = h.Numerator;
   a = 1;
else
   a = p.Results.a;
end

for i = 1:numel(self)
   for j = 1:size(self(i).window,1)
      if p.Results.compesateDelay
         self(i).values{j} = filtfilt(b,a,self(i).values{j});
      else
         self(i).values{j} = filter(b,a,self(i).values{j});
      end
   end
end
