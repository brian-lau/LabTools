function y = powmedfilt(f,x)
% f = (0:.25:500)';
% x = 1./f;
% %x = x + .1*randn(size(x));
% 
logw = 1;
logf = log(f);
lowerEdge = exp(logf-logw);
lowerEdge = max(lowerEdge,f(1));
upperEdge = exp(logf+logw);
upperEdge = min(upperEdge,f(end));

y = zeros(size(x));
for i = 1:numel(x)
   ind = (f >= lowerEdge(i)) & (f <= upperEdge(i));
   y(i) = median(x(ind,:));
end