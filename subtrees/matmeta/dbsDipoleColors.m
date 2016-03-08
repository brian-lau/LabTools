classdef dbsDipoleColors
   properties
      R
      G
      B
   end
   methods
      function c = dbsDipoleColors(r, g, b)
         c.R = r; c.G = g; c.B = b;
      end
   end
   enumeration
      Error   (1, 0, 0)
      Comment (0, 1, 0)
      Keyword (0, 0, 1)
      String  (1, 0, 1)
   end
end