function [self,b] = bandstop(self,corner,varargin)

p = inputParser;
p.KeepUnmatched = true;
addRequired(p,'corner',@(x) isnumeric(x) && (numel(x)==2) && all(x>0));
addParamValue(p,'order',[],@isnumeric);
addParamValue(p,'method','firws',@ischar);
addParamValue(p,'window','blackman',@ischar);
addParamValue(p,'tbw',2,@isnumeric);
addParamValue(p,'fix',false,@islogical);
addParamValue(p,'plot',false,@islogical);
parse(p,corner,varargin{:});

Fs = unique([self.Fs]);
assert(numel(Fs)==1,'Must have same Fs');
nyquist = self.Fs/2;

assert(corner(2)>corner(1),'Second bandedge must be higher than first');
assert(corner(2)>p.Results.tbw,'Corner too low for transition bandwidth');
assert(((corner(1)+p.Results.tbw)/nyquist)<1,'Corner too high for transition bandwidth');

if isempty(p.Results.order)
   order = pop_firwsord(p.Results.window,Fs,p.Results.tbw);
else
   order = p.Results.order;
end

switch lower(p.Results.method)
   case 'firls'
      b = firls(order,[0 (corner(1)-p.Results.tbw)/nyquist corner(1)/nyquist...
         corner(2)/nyquist (corner(2)+p.Results.tbw)/nyquist 1],[1 1 0 0 1 1]);
      a = 1;
   case 'firws'
      [b,a] = firws(order,corner/nyquist,'stop');
   otherwise
      error('Unknown FIR filter design method');
end
self.filter(b,'a',a,'fix',p.Results.fix);

if p.Results.plot
   plotfresp(b,a,order,Fs);
end
