% Shifted power law
% http://tuvalu.santafe.edu/~aaronc/courses/7000/csci7000-001_2011_L2.pdf
function y = shiftedpl(b,x)

a = b(1);
k = b(2);
alpha = b(3);

%y = zeros(size(x));

if k == 0
   y = a * x.^(-alpha);
else
   y = a * ((k + x)./k).^(-alpha);
end