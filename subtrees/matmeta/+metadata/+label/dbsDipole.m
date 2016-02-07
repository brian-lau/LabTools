% 
classdef dbsDipole < metadata.Label
   properties
      side
      contacts
      %x
      %y
      %z
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
         p.parse(varargin{:});
         par = p.Results;
         
         self.side = par.side;
         self.contacts = par.contacts;
      end
   end
end