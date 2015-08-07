classdef StreamTest < handle
   properties(SetAccess = protected)
      tStart
      Fs
      dim
      data
   end
   
   methods
      function self = StreamTest(data,varargin)
         self.tStart = 0;
         self.Fs = 1000;
         self.dim = size(data);
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
