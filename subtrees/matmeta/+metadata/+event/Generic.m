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
      end
   end
end