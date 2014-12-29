% resample data in window
function self = resample(self,newFs,varargin)

p = inputParser;
p.KeepUnmatched = true;
addRequired(p,'newFs',@(x) isnumeric(x) && isscalar(x));
addParamValue(p,'fix',false,@islogical);
parse(p,newFs,varargin{:});

for i = 1:numel(self)
   if self(i).Fs == newFs
      continue;
   end
   
   % use lcm?
   % http://www.mathworks.com/matlabcentral/fileexchange/45329-sample-rate-conversion/content/SRC/srconv.m
   [n,d] = rat(newFs/self(i).Fs);
   
   if p.Results.fix
      % Resample continuous original values, reapply window/offset
      % This discards all currently applied transformations!
      self(i).values_ = resample(self(i).values_,n,d);
      self(i).Fs_ = newFs;
      self(i).Fs = newFs;
      self(i).times_ = self(i).tvec(self(i).tStart,self(i).dt,size(self(i).values_,1));
      oldOffset = self(i).offset;
      applyWindow(self(i));
      self(i).offset = oldOffset;
   else
      % Resample first window and cache the filter
      [values{1},b] = resample(self(i).values{1},n,d);
      nWindow = size(self(i).window,1);
      if nWindow > 1
         values(2:nWindow,1) = cellfun(@(x) resample(x,n,d,b),...
            self(i).values(2:nWindow,1),'uni',0);
      end
      
      times = cellfun(@(x,y) self(i).tvec(x(1),1/newFs,size(y,1)),...
         self(i).times,values,'uni',0);
      
      self(i).times = times;
      self(i).values = values;
      self(i).Fs = newFs;
   end
end