% 
classdef dbsDipole < metadata.Label
   properties
      side
      contacts
      coordinateSystem
      x
      y
      z
   end
   methods
      function self = dbsDipole(varargin)
         self = self@metadata.Label(varargin{:});
         if nargin == 0
            return;
         end
         
         p = inputParser;
         p.KeepUnmatched= true;
         p.FunctionName = 'dbsDipole constructor';
         p.addParameter('side','',@ischar);
         p.addParameter('contacts','',@ischar);
         p.addParameter('coordinateSystem','',@ischar);
         p.addParameter('x',[],@(x) isnumeric(x) && isscalar(x));
         p.addParameter('y',[],@(x) isnumeric(x) && isscalar(x));
         p.addParameter('z',{},@(x) isnumeric(x) && isscalar(x));
         p.parse(varargin{:});
         par = p.Results;
         
         self.side = par.side;
         self.contacts = par.contacts;
      end
   end
end