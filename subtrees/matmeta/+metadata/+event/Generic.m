classdef Generic < metadata.Event
   methods
      function self = Generic(varargin)
         self = self@metadata.Event(varargin{:});
      end
   end
end