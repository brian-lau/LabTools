classdef Generic < metadata.Event
   properties
      value
   end
   methods
      function self = Generic(varargin)
         self = self@metadata.Event(varargin{:});
         if nargin == 0
            return;
         end
         
         p = inputParser;
         p.KeepUnmatched= true;
         p.FunctionName = 'Generic constructor';
         p.addParameter('value',[]);
         p.parse(varargin{:});
         par = p.Results;
         
         self.value = par.value;
         
         % Default color
         if ~any(strcmp(varargin,'color'))
            if isa(self.name,'metadata.Label')
               if all(self.name.color == [0.2 0.2 0.2])
                  self.name.color = [255 255 1]/255;
               end
            end
         end
      end
   end
end