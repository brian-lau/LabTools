% TODO
%  o IIR filters?

function [self,b,a] = lowpass(self,corner,varargin)

p = inputParser;
p.KeepUnmatched = true;
addRequired(p,'corner',@(x) isnumeric(x) && isscalar(x) && (x>0));
addParamValue(p,'order',[],@isnumeric);
addParamValue(p,'method','firws',@ischar);
addParamValue(p,'tbw',2,@isnumeric);
addParamValue(p,'window','blackman',@ischar);
addParamValue(p,'fix',false,@islogical);
addParamValue(p,'plot',false,@islogical);
parse(p,corner,varargin{:});

Fs = unique([self.Fs]);
assert(numel(Fs)==1,'Must have same Fs');
nyquist = self.Fs/2;

assert(((corner+p.Results.tbw)/nyquist)<1,'Corner too high for transition bandwidth');

if isempty(p.Results.order)
   order = pop_firwsord(p.Results.window,Fs,p.Results.tbw);
else
   order = p.Results.order;
end

switch lower(p.Results.method)
   case 'firls'
      b = firls(order,[0 corner/nyquist (corner+p.Results.tbw)/nyquist 1],[1 1 0 0]);
      a = 1;
   case 'firws'
      [b,a] = firws(order,corner/nyquist,'low');
   otherwise
      error('Unknown FIR filter design method');
end
self.filter(b,'a',a,'fix',p.Results.fix);

if p.Results.plot
   %freqz(b,a,[],'whole',Fs);
   plotfresp(b,a,order,Fs);
end
