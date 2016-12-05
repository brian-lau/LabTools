% 
classdef dbsUnit < metadata.Label
   properties
      side
      electrode
      area
      coordinateSystem
      x
      y
      z
      snr
   end
   methods
      function self = dbsUnit(varargin)
         % Single string input == name
         if (nargin == 1)
            x = varargin{1};
            if ischar(x)
               varargin{1} = 'name';
               varargin{2} = x;
            end
         end

         self = self@metadata.Label(varargin{:});
         if nargin == 0
            return;
         end
         
         p = inputParser;
         p.KeepUnmatched= true;
         p.FunctionName = 'dbsDipole constructor';
         p.addParameter('side','r',@ischar);
         p.addParameter('electrode','',@(x) ischar(x) || isnumeric(x));
         p.addParameter('area','',@ischar);
         p.addParameter('coordinateSystem','',@ischar);
         p.addParameter('x',[],@(x) isnumeric(x) && isscalar(x));
         p.addParameter('y',[],@(x) isnumeric(x) && isscalar(x));
         p.addParameter('z',[],@(x) isnumeric(x) && isscalar(x));
         p.addParameter('snr',[],@(x) isnumeric(x));
         p.parse(varargin{:});
         par = p.Results;
         
         self.side = par.side;
         self.electrode = par.electrode;
         self.area = par.area;
         self.coordinateSystem = par.coordinateSystem;
         self.x = par.x;
         self.y = par.y;
         self.z = par.z;
         self.snr = par.snr;
         defaultColor(self);
      end
      
      function set.side(self,side)
         assert(ischar(side),'Side must be a string');
         switch lower(side)
            case {'l' 'g'}
               self.side = 'left';
            case {'r' 'd'}
               self.side = 'right';
            otherwise
               error('invalid side');
         end
      end
      
      function defaultColor(self)
         % DEFINE
      end
      
   end
end