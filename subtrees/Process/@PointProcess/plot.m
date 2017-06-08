% Raster plot
%
% For a full description of the possible parameters,
%
% SEE ALSO
% plotRaster

function [hh,yOffset] = plot(self,varargin)

import spk.*

p = inputParser;
p.KeepUnmatched= true;
p.FunctionName = 'PointProcess raster method';
% Intercept some parameters to override defaults
p.addParameter('grpBorder',false,@islogical);
p.addParameter('labelXAxis',false,@islogical);
p.addParameter('labelYAxis',false,@islogical);
p.parse(varargin{:});
% Passed through to plotRaster
params = p.Unmatched;

n = numel(self);
if n == 1
   times = self.times;
else
   times = cat(1,self.times);
   %window = self.checkWindow(cat(1,self.window),n);
end

if isempty(times)
   % need to return handle and yOffset if they exist? TODO
   if isfield(params,'h')
      h = params.h;
   end
   if isfield(params,'yOffset')
      yOff = params.yOffset;
   end
else
   [h,yOff] = plotRaster(times,p.Results,params);
   xlabel('Time');
   %xlabel(['Time (' self.unit ')']);
end

if nargout == 1
   hh = h;
elseif nargout == 2
   hh = h;
   yOffset = yOff;
end