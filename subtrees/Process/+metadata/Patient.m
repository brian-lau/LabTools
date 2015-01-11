% 
classdef Patient < metadata.Subject
   properties
      exam
      intervention
   end
%    properties(SetAccess = private, Dependent = true, Transient = true)
%       %timeSinceExam
%       timeSinceIntervention
%    end
   methods
      function self = Patient(varargin)
         self = self@metadata.Subject(varargin{:});
         if nargin == 0
            return;
         end
         
         p = inputParser;
         p.KeepUnmatched= true;
         p.FunctionName = 'Patient constructor';
         p.addParamValue('method','',@ischar);
         p.parse(varargin{:});
         par = p.Results;
         
         self.method = par.method;
      end
   end
end