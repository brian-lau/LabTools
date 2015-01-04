% MINOR                      Matrix minor
% 
%     m = minor(M,i,j);
%
%     INPUTS
%     M - matrix
%     i - row index
%     j - column index
%
%     OUTPUTS
%     m - determinant
%

%     $ Copyright 2007 Brian Lau <brian.lau@columbia.edu> $
%
%     REVISION HISTORY:
%     brian 08.20.07 written 

function m = minor(M,i,j);

[m,n] = size(M);

if m ~= n
   error('Input must be square for MINOR');
end

M(i,:) = [];
M(:,j) = [];
m = det(M);

return