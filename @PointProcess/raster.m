% Raster plot
%
% For a full description of the possible parameters,
%
% SEE ALSO
% plotRaster

function [h,yOffset] = raster(self,varargin)

import spk.*

p = inputParser;
p.KeepUnmatched= true;
p.FunctionName = 'PointProcess raster method';
% Intercept some parameters to override defaults
p.addParamValue('grpBorder',false,@islogical);
p.addParamValue('labelXAxis',false,@islogical);
p.addParamValue('labelYAxis',false,@islogical);
p.parse(varargin{:});
% Passed through to plotRaster
params = p.Unmatched;

n = numel(self);
if n == 1
   times = self.times;
else
   times = [self.times];
   %window = self.checkWindow(cat(1,self.window),n);
end

if isempty(times)
   % need to return handle and yOffset if they exist? TODO
   if isfield(params,'h')
      h = params.h;
   end
   if isfield(params,'yOffset')
      yOffset = params.yOffset;
   end
else
   [h,yOffset] = plotRaster(times,p.Results,params);
   xlabel('Time');
   %xlabel(['Time (' self.unit ')']);
end
