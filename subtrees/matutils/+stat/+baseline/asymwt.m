% Asymmetric penalty 
% http://eeweb.poly.edu/iselesni/pubs/BEADS_2014.pdf
function wt = asymwt(fit,actual)

r = 0.25;
d = fit - actual;
wt = d;
wt(d<0) = -r*d(d<0);

% eta = 0.01;
% r = 1/.25;
% d = fit - actual;
% 
% wt = d;
% wt(d<eta) = -r*d(d<eta);
% d2 = d(abs(d)<=eta);
% wt(abs(d)<=eta) = ((1+r)/(4*eta)).*d2.^2 + ((1-r)/2).*d2 + eta*((1+r)/4);
% 
