classdef Trial < metadata.Section
   properties
      experiment@metadata.Experiment
      protocol@metadata.Protocol
   end
   properties(Abstract=true,SetAccess=protected)
      version
   end
   methods
      function self = Trial(varargin)
         self = self@metadata.Section;
      end
   end
end