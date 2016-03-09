% 
classdef Artifact < metadata.Event
   properties
      method
   end
   methods
      function self = Artifact(varargin)
         self = self@metadata.Event(varargin{:});
         if nargin == 0
            return;
         end
         
         p = inputParser;
         p.KeepUnmatched = true;
         p.FunctionName = 'Artifact constructor';
         p.addParamValue('method','',@ischar);
         p.parse(varargin{:});
         par = p.Results;
                  
         self.method = par.method;
         
         % Default color
         if ~any(strcmp(varargin,'color'))
            if isa(self.name,'metadata.Label')
               self.name.color = [0 0 0];
            else
               %warning('no color set');
            end
         end
      end
   end
end