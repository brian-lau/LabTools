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
         p.KeepUnmatched= true;
         p.addParameter('name','');
         p.addParameter('description','');
         p.addParameter('comment','');
         p.addParameter('grouping','');
         p.parse(varargin{:});
         par = p.Results;
         
         self.name = par.name;
         self.description = par.description;
         self.comment = par.comment;
         self.grouping = par.grouping;
      end
      
   end
end