% TODO
%   o edge padding, handle nan padding (filter state?, replace nans?)
%   x different filtering methods (causal, etc.)
%   o batched (looped) filtering (eg. for memmapped data)
%   o compensateDelay should be 'filtfilt' 'grpdelay' 'none',
%     then add parameter in filtering functions to compensate if using
%     filtfilt (halve order, and sqrt attenuation/ripple)?
%   o should filtering functions only design filters? or have 'filter' bool
%   o fftfilt for speed?

function self = filter(self,b,varargin)

p = inputParser;
p.KeepUnmatched = true;
addRequired(p,'b',@(x) isnumeric(x) || isa(x,'dfilt.dffir'));
addParameter(p,'a',1,@isnumeric);
addParameter(p,'compensateDelay',true,@islogical);
parse(p,b,varargin{:});
par = p.Results;

if isa(b,'dfilt.dffir')
   h = b;
   b = h.Numerator;
   a = 1;
   %groupDelay = (length(b) - 1) / 2;
else
   a = par.a;
   %groupDelay = mean(grpdelay(b,a));
end

for i = 1:numel(self)
   %------- Add to function queue ----------
   if isQueueable(self(i))
      addToQueue(self(i),par);
      if self(i).deferredEval
         continue;
      end
   end
   %----------------------------------------

   for j = 1:size(self(i).window,1)
      if par.compensateDelay
         %temp = self(i).values{j};
         self(i).values{j} = filtfilt(b,a,self(i).values{j});
      else
         self(i).values{j} = filter(b,a,self(i).values{j});
      end
   end
end
