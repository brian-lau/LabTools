classdef Label < metadata.Section
   properties
      name
      description
      comment
      grouping
   end
   properties(SetAccess = protected)
      timeFormat = 'HH:MM'
   end
   
   methods
      function self = Label(varargin)
         self = self@metadata.Section();
         if nargin == 0
            return;
         end
         
         p = inputParser;
         p.KeepUnmatched= false;
         p.FunctionName = 'Experiment constructor';
         p.addParamValue('name','',@ischar);
         p.addParamValue('description','',@ischar);
         p.addParamValue('comment','',@ischar);
         p.addParamValue('grouping','',@(x) isscalar(x) || ischar(x));
         p.parse(varargin{:});
         par = p.Results;
         
         self.name = par.name;
         self.description = par.description;
         self.comment = par.comment;
         self.date = par.grouping;
      end
      
   end
end