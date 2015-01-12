classdef UPDRS < metadata.Exam
   properties
      
      %LEDD %?
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
      item18
      item19
      item20a
      item20b
      item20c
      item20d
      item20e
      item21a
      item21b
      item22a
      item22b
      item22c
      item22d
      item22e
      item23a
      item23b
      item24a
      item24b
      item25a
      item25b
      item26a
      item26b
      item27
      item28
      item29
      item30
      item31
      item32
      item33
      item34
      item35
      item36
      item37
      item38
      item39
      item40
      item41
      item42
      
      HoehnYahr
      SchwabEngland
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