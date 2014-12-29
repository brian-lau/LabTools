function [self,b] = highpass(self,corner,varargin)

p = inputParser;
p.KeepUnmatched = true;
addRequired(p,'corner',@isnumeric);
addParamValue(p,'order',[],@isnumeric);
addParamValue(p,'method','firws',@ischar);
addParamValue(p,'tbw',2,@isnumeric);
addParamValue(p,'fix',false,@islogical);
addParamValue(p,'plot',false,@islogical);
parse(p,corner,varargin{:});

assert(corner > (corner-1),'Corner frequency too low');
Fs = unique([self.Fs]);
assert(numel(Fs)==1,'Must have same Fs');
nyquist = self.Fs/2;

if isempty(p.Results.order)
   order = pop_firwsord('hamming',Fs,p.Results.tbw);
else
   order = p.Results.order;
end

switch lower(p.Results.method)
   case 'firls'
      b = firls(order,[0 (corner-1)/nyquist corner/nyquist 1],[0 0 1 1]);
   case 'firws'
      b = firws(order,corner/nyquist,'high');
   otherwise
      error('Unknown FIR filter design method');
end
self.filter(b,'fix',p.Results.fix);

if p.Results.plot
   freqz(b,1,[],'whole',Fs);
end
