classdef Subject < metadata.Section
   properties 
      id
      comment
      dateOfBirth
   end
   properties(SetAccess = private, Dependent = true, Transient = true)
      age
   end
   methods
      function self = Subject(varargin)
         self = self@metadata.Section();
         if nargin == 0
            return;
         end
         
         p = inputParser;
         p.KeepUnmatched= false;
         p.FunctionName = 'Subject constructor';
         p.addParamValue('id','',@(x) ischar(x)||isscalar(x));
         p.addParamValue('comment','',@ischar);
         p.addParamValue('dateOfBirth','',@ischar);
         p.parse(varargin{:});
         par = p.Results;
         
         self.id = par.id;
         self.comment = par.comment;
         self.dateOfBirth = par.dateOfBirth;
      end
      
      function age = get.age(self)
         if isempty(self.dateOfBirth)
            age = [];
         else
            dob = datenum(self.dateOfBirth,self.dateFormat);
            age = datevec(now - dob);
         end
      end
      
      function set.dateOfBirth(self,str)
         if ~isempty(str)
            [bool,str] = self.isValidDateStr(str,self.dateFormat);
            if bool
               self.dateOfBirth = str;
            end
         end
      end
   end
end