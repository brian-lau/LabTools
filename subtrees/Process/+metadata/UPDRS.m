classdef UPDRS < metadata.Exam
   properties
      
      LEDD %?
      item1
      item2
      item3
      item4
      item5
      item6
      item7
      item8
      item9
      item10
      item11
      item12
      item13
      item14
      item15
      item16
      item17
      
      HoehnYahr
      
   end
   properties(SetAccess = private, Dependent = true, Transient = true)
      akinesia
      bradykinesia
      tremor
   end
   
   methods
      function self = UPDRS(varargin)
         self = self@metadata.Exam(varargin{:});
         if nargin == 0
            return;
         end
      end
   end
end