% smoothly broken power law
% DOI: 10.1051/0004-6361/201015581
% http://arxiv.org/pdf/1305.0809.pdf
% http://www.aanda.org/articles/aa/full/2007/21/aa7055-07/aa7055-07.right.html
function y = brokenpl(b,x)

c = b(1);
n = b(2);
alpha1 = b(3);
alpha2 = b(4);
xb = b(5);

y = c * ( (x./xb).^(alpha1*n) + (x./xb).^(alpha2*n) ).^(-1/n);