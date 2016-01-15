function varargout = plot(self,varargin)

[h,yOffset] = raster(self,varargin{:});

if nargout == 1
   varargout{1} = h;
elseif nargout == 2
   varargout{1} = h;
   varargout{2} = yOffset;
end