classdef DBS < metadata.Intervention
   properties
      
      localization
   end
   methods
      function self = DBS(varargin)
         self = self@metadata.Intervention(varargin{:});
         if nargin == 0
            return;
         end
      end
   end
end