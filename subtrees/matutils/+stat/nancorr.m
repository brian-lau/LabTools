% correlation coefficients, removing all rows with any NaNs.
% arguments passed through to corr
function [coef,pval,n] = nancorr(x,varargin)

x(any(isnan(x),2),:) = [];
[coef,pval] = corr(x,varargin{:});
if nargout == 3
   n = size(x,1);
end
