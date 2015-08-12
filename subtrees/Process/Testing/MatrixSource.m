classdef MatrixSource < DataSource
   
   methods
      function self = MatrixSource(data,varargin)
         self = self@DataSource;
         if nargin == 0
            return;
         end
         
         self.tStart = 0;
         self.Fs = 1000;
         self.dim = size(data);
         self.data = data;
      end
   end
end
