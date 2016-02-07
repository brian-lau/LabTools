classdef Label < handle & matlab.mixin.Heterogeneous
   properties
      name
      description
      comment
      grouping
   end
   
   methods
      function self = Label(varargin)
         if nargin == 0
            return;
         end
         
         p = inputParser;
         p.KeepUnmatched= false;
         p.FunctionName = 'Label constructor';
         p.addParameter('name','',@ischar);
         p.addParameter('description','',@ischar);
         p.addParameter('comment','',@ischar);
         p.addParameter('grouping','',@(x) isscalar(x) || ischar(x));
         p.parse(varargin{:});
         par = p.Results;
         
         self.name = par.name;
         self.description = par.description;
         self.comment = par.comment;
         self.grouping = par.grouping;
      end
      
   end
end