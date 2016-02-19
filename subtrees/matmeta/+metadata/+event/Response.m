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
         p.addParameter('modality','',@ischar);
         p.parse(varargin{:});
         par = p.Results;
         
         self.modality = par.modality;
      end
   end

end