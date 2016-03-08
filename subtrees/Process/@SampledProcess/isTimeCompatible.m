% TODO this will not work properly with multiple windows
% dt
% relwindow
% previously, I exactly matched the time vectors, but I'm worried that this
% will fail due to small floating point inaccuracies that accumulate
% this also suggests that even with exact window/tStep/tBlock/offset, we
% could end up with a missing sample at the beginning end of window?

function [bool,rw,dt,t] = isTimeCompatible(self)

tolerance = 1e-13;
maxdiff = @(x) max(max(x)-min(x));

if numel(self) == 1
   bool = true;
   rw = true;
   dt = true;
   t = true;
   return;
end

rw = false;
dt = false;
t = false;

try
   relWindow = cat(1,self.relWindow);
   if maxdiff(relWindow) < tolerance
      rw = true;
   end
catch err
   if ~strcmp(err.identifier,'MATLAB:catenate:dimensionMismatch')
      rethrow(err);
   end
end

try
   dt = cat(1,self.dt);
   if maxdiff(dt) < tolerance
      dt = true;
   end
catch err
   if ~strcmp(err.identifier,'MATLAB:catenate:dimensionMismatch')
      rethrow(err);
   end
end

try
   times = cat(2,self.times);
   times = cat(2,times{:})';
   if maxdiff(times) < tolerance
      t = true;
   end
catch err
   if ~strcmp(err.identifier,'MATLAB:catenate:dimensionMismatch')
      rethrow(err);
   end
end

bool = all([rw dt t]);
