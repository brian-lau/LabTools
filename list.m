%
% [a,b,c] = list([1 2 3])
% 
function varargout = list(x)

if isnumeric(x)
   x = num2cell(x);
end
varargout = x(1:nargout);