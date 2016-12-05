% Section
classdef Section %< hgsetget %& matlab.mixin.Heterogeneous %& matlab.mixin.Copyable
   properties
      type
   end
   properties(SetAccess = protected)
      dateFormat = 'dd/mm/yyyy'
   end
   
   methods
      function self = Section()
         m = metaclass(self);
         self.type = m.Name;
      end
   end
   
   methods(Static)
      function [valid,str] = isValidDateStr(str,format)
         % Java & Matlab differ in month case
         format = strrep(format,'m','M');
         d = java.text.SimpleDateFormat(format);
         d.setLenient(false);
         try
            d.parse(str);
            str = datestr(datenum(str,format),format);
            valid = true;
         catch err
            valid = false;
            % FIXME throw an error
         end
      end
   end
end