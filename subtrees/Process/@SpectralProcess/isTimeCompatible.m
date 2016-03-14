% TODO this will not work properly with multiple windows
% dt
% relwindow
% previously, I exactly matched the time vectors, but I'm worried that this
% will fail due to small floating point inaccuracies that accumulate
% this also suggests that even with exact window/tStep/tBlock/offset, we
% could end up with a missing sample at the beginning end of window?
% s = SampledProcess((1:10)')
% 
% s(2) = SampledProcess((1:10)')
% s(2).offset = .00001
% s(1).window = [0 9]
% s(2).window = [0 9]-.00001
% 
% s = SampledProcess((1:10)')
% s(2) = SampledProcess((1:10)')
% s(2).labels(1) = s(1).labels;

function [bool,rw,dt,tb,t] = isTimeCompatible(self)

tolerance = 1e-13;
maxdiff = @(x) max(max(x)-min(x));

if numel(self) == 1
   bool = true;
   rw = true;
   dt = true;
   tb = true;
   t = true;
   return;
end

rw = false;
dt = false;
tb = false;
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
   tBlock = cat(1,self.tBlock);
   if maxdiff(tBlock) < tolerance
      tb = true;
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

bool = all([rw dt tb t]);
