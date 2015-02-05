classdef Protocol < metadata.Section
   properties 
      name
      description
      version
      experiment
   end
   methods
      function self = Protocol(varargin)
         self = self@metadata.Section();
         if nargin == 0
            return;
         end
         
         p = inputParser;
         p.KeepUnmatched= false;
         p.FunctionName = 'Protocol constructor';
         p.addParamValue('name','',@ischar);
         p.addParamValue('description','',@ischar);
         p.addParamValue('version','',@(x) ischar(x)||isscalar(x));
         p.parse(varargin{:});
         par = p.Results;
         
         self.name = par.name;
         self.description = par.description;
         self.version = par.version;
      end
   end
end