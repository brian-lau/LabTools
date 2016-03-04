% TODO
%   o edge padding, handle nan padding (filter state?, replace nans?)
%   x different filtering methods (causal, etc.)
%   o batched (looped) filtering (eg. for memmapped data)
function self = filter(self,f,varargin)

p = inputParser;
p.KeepUnmatched = true;
addRequired(p,'f',@(x) isnumeric(x) || isa(x,'dfilt.dffir') || isa(x,'digitalFilter'));
addParameter(p,'compensateDelay',true,@islogical);
addParameter(p,'padmode',true,@islogical);
parse(p,f,varargin{:});
par = p.Results;

if isa(f,'dfilt.dffir')
   b = f.Numerator;
   fir = true;
elseif isa(f,'digitalFilter')
   b = f.Coefficients;
   if strcmp(f.ImpulseResponse,'fir')
      fir = true;
   else
      error('not FIR'); %TODO
   end
else
   fir = true;
end

if fir && isodd(numel(b)) && par.compensateDelay
   gd = (length(b) - 1) / 2;
elseif fir && par.compensateDelay % TO TEST
   disp('Filter is not linear-phase FIR or has non-integer group delay, using average group delay');
   gd = fix(mean(grpdelay(b,1)));
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
         temp = self(i).values{j};
         temp = [temp(gd+1:-1:2,:) ; temp ; temp(end-1:-1:end-gd,:)];
         temp = filter(b,1,temp);
         self(i).values{j} = temp(2*gd+1:2*gd+self(i).dim{j}(1),:);
      else
         self(i).values{j} = filter(b,1,self(i).values{j});
      end
   end
end
