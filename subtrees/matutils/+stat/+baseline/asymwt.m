% Asymmetric penalty 
% http://eeweb.poly.edu/iselesni/pubs/BEADS_2014.pdf
function wt = asymwt(y,z)
r = 0.25;
%r = 0.05;
d = y - z;
wt = d;
wt(d<0) = -r*d(d<0);