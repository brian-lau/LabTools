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
         
      end
   end
end