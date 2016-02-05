classdef(CaseInsensitiveProperties, TruncatedProperties) Block < hgsetget & matlab.mixin.Copyable
   properties
      info@containers.Map % Information about segment
   end
   properties(SetAccess = private)
      segments
   end
   properties
      labels
   end
   properties(SetAccess = protected)
      version = '0.1.0'
   end
   
   methods
   end
end