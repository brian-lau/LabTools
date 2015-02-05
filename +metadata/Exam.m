classdef Exam < metadata.Experiment
   properties
      clinician
      url
   end
   methods
      function self = Exam(varargin)
         self = self@metadata.Experiment(varargin{:});
         if nargin == 0
            return;
         end
      end
   end
end