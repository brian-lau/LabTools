function [hh,yOffset] = plot(self,varargin)

[h,yOff] = raster(self,varargin{:});

if nargout == 1
   hh = h;
elseif nargout == 2
   hh = h;
   yOffset = yOff;
end