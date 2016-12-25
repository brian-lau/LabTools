% smoothly broken power law
% DOI: 10.1051/0004-6361/201015581
%
% http://arxiv.org/pdf/1305.0809.pdf
% http://www.aanda.org/articles/aa/full/2007/21/aa7055-07/aa7055-07.right.html
function y = smbrokenpl(b,x)

if numel(b) == 5
   c = b(1);
   n = b(2);
   alpha1 = b(3);
   alpha2 = b(4);
   xb = b(5);
   
   y = c * ( (x./xb).^(alpha1*n) + (x./xb).^(alpha2*n) ).^(-1/n);
elseif numel(b) == 8
   % http://iopscience.iop.org/article/10.1086/524701/pdf
   c = b(1);       % f0
   n = b(2);       % omega1
   alpha1 = b(3);  % alpha2
   alpha2 = b(4);  % alpha3
   xb = b(5);      % t_{b,1}
   n2 = b(6);      % omega2
   alpha3 = b(7);  % alpha4
   xb2 = b(8);     % t_{b,2}
   
   y = c * ( (x./xb).^(alpha1*n) + (x./xb).^(alpha2*n) ).^(-1/n);
   yj = y .* (x/xb2).^(-alpha3);
   y = (y.^(-n2) + yj.^(-n2)).^(-1/n2);
end

%y = c * xb.^(-alpha1) .* ( (x./xb).^(alpha1*n) + (x./xb).^(alpha2*n) ).^(-1/n);