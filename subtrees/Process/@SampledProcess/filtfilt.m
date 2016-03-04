
function self = filtfilt(self,f,varargin)

p = inputParser;
p.KeepUnmatched = true;
addRequired(p,'f',@(x) isnumeric(x) || isa(x,'dfilt.dffir') || isa(x,'digitalFilter'));
parse(p,f,varargin{:});
par = p.Results;

if isa(f,'dfilt.dffir')
   b = f.Numerator;
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
      if isa(b,'digitalFilter')
         self(i).values{j} = filtfilt(h,self(i).values{j});
      else
         self(i).values{j} = filtfilt(b,1,self(i).values{j});
      end
   end
end
