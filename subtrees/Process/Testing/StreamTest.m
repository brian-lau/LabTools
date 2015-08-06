classdef StreamTest < handle
   properties
      n
      data
   end
   
   methods
      function self = StreamTest(data,varargin)
         %keyboard
         self.n = size(data,1);
         self.data = data;
      end
      function dim = size(self)
         dim = size(self.data);
      end
      function B = subsref(self,S)
         % Handle the first indexing on object itself, shorcut place()
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
