% Missing data
classdef Gap < metadata.Event
   properties
      
   end
   methods
      function self = Gap(varargin)
         self = self@metadata.Event(varargin{:});
         if nargin == 0
            return;
         end
         
         p = inputParser;
         p.KeepUnmatched= true;
         p.FunctionName = 'Gap constructor';
         p.parse(varargin{:});
         par = p.Results;
         
         % Default color
         if ~any(strcmp(varargin,'color'))
            if isa(self.name,'metadata.Label')
               self.name.color = [152 78 163]/255;
            else
               %warning('no color set');
            end
         end
      end
   end
end