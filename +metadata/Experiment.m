classdef Experiment < metadata.Section
   properties
      name
      description
      comment
      date
      time
      protocol
   end
   properties(SetAccess = protected)
      timeFormat = 'HH:MM'
   end
   
   methods
      function self = Experiment(varargin)
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
         p.addParamValue('date','',@ischar);
         p.addParamValue('time','',@(x) ischar(x)||isscalar(x));
         p.addParamValue('protocol',[],@(x) isa(x,'metadata.Protocol'));
         p.parse(varargin{:});
         par = p.Results;
         
         self.name = par.name;
         self.description = par.description;
         self.comment = par.comment;
         self.date = par.date;
         self.time = par.time;
         self.protocol = par.protocol;
      end
      
      function set.date(self,str)
         if ~isempty(str)
            [bool,str] = self.isValidDateStr(str,self.dateFormat);
            if bool
               self.date = str;
            end
         end
      end
   end
end