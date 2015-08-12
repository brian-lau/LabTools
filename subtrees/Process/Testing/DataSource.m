classdef(Abstract) DataSource < handle
   properties(SetAccess = protected)
      tStart
      Fs
      dim
      data
   end
   
   methods
      
      function dim = size(self)
         dim = size(self.data);
      end
      
      function B = subsref(self,S)
         % Shortcut direct access to data
         switch S(1).type
            case '()'
               B = self.data(S(1).subs{:});
               if numel(S) > 1
                  B = builtin('subsref',self,S(2:end));
               end
            otherwise
               % Enable normal "." and "{}" behavior
               B = builtin('subsref',self,S);
         end
      end
   end
end
