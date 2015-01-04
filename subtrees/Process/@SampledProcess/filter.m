% TODO
%   o edge padding
%   o what happens with nans?
%   o different filtering methods (causal, etc.)

function self = filter(self,b,varargin)

p = inputParser;
p.KeepUnmatched = true;
addRequired(p,'b',@isnumeric);
addParamValue(p,'a',1,@isnumeric);
addParamValue(p,'fix',false,@islogical);
parse(p,b,varargin{:});

a = p.Results.a;

for i = 1:numel(self)
   for j = 1:size(self(i).window,1)
      if p.Results.fix
         % Filter continuous original values, reapply window/offset
         % This discards all currently applied transformations!
         self(i).values_ = filtfilt(b,a,self(i).values_);
         oldOffset = self(i).offset;
         applyWindow(self(i));
         self(i).offset = oldOffset;
      else
         self(i).values{j} = filtfilt(b,a,self(i).values{j});
      end
   end
end
