classdef Intervention < metadata.Experiment
   properties
      clinician
   end
   methods
      function self = Intervention(varargin)
         self = self@metadata.Experiment(varargin{:});
         if nargin == 0
            return;
         end
      end
   end
end