classdef Response < metadata.Event
   properties
      modality
   end
   methods
      function self = Response(varargin)
         self = self@metadata.Event(varargin{:});
         if nargin == 0
            return;
         end
         
         p = inputParser;
         p.KeepUnmatched= true;
         p.FunctionName = 'Response constructor';
         p.addParamValue('modality','',@ischar);
         p.parse(varargin{:});
         par = p.Results;
         
         self.modality = par.modality;
         
         % Default color
         if ~any(strcmp(varargin,'color'))
            if isa(self.name,'metadata.Label')
               self.name.color = [55 126 184]/255;
            else
               %warning('no color set');
            end
         end
      end
   end

end