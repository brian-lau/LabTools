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
               if all(self.name.color == [0.2 0.2 0.2])
                  self.name.color = [0 0 0];
               end
            end
         end
      end
   end
end