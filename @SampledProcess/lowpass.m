function [self,b] = lowpass(self,corner,varargin)

p = inputParser;
p.KeepUnmatched = true;
addRequired(p,'corner',@isnumeric);
addParamValue(p,'order',[],@isnumeric);
addParamValue(p,'method','firls',@ischar);
addParamValue(p,'fix',false,@islogical);
addParamValue(p,'plot',false,@islogical);
parse(p,corner,varargin{:});

Fs = unique([self.Fs]);
assert(numel(Fs)==1,'Must have same Fs');
assert(corner > Fs,'Corner frequency too high');
nyquist = self.Fs/2;

if isempty(p.Results.order)
   order = Fs;
else
   order = p.Results.order;
end

switch lower(p.Results.method)
   case 'firls'
      b = firls(order,[0 (corner-1)/nyquist corner/nyquist 1],[1 1 0 0]);
   otherwise
      error('Unknown FIR filter design method');
end
self.filter(b,'fix',p.Results.fix);

if p.Results.plot
   freqz(b,1,[],'whole',Fs);
end
