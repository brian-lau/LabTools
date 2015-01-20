classdef Trial < metadata.Section
   properties 
      block
      condition
      number
   end
   methods
      function self = Trial(n)
         self = self@metadata.Section;
         self.number = n;
      end
   end
end