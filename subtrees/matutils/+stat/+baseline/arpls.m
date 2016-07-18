% Smooth data using asymmetrically reweighted penalized least squares
% 
%     lambda - scalar, optional, default = 1e7
%              Regularization parameter, larger is smoother, adjust
%              logarithmically (ie, 1e7, 1e3, etc).
%     ratio  - scalar, optional, default 1e-3
%              Termination criterion
% 
% Baek et al (2015). Baseline correction using asymmetrically reweighted
%   penalized least squares smoothing. Analyst 140: 250-257.
function z = arpls(y,lambda,ratio)

if nargin < 3
   ratio = 1e-3;
end

if nargin < 2
   lambda = 1e7;
end

maxiter = 100;

N = length(y);
D = diff(speye(N),2);
H = lambda*D'*D;
w = ones(N,1);
count = 1;
while true
   W = spdiags(w,0,N,N);
   C = chol(W + H);
   z = C \ ( C'\(w.*y) );
   d = y - z;
   dn = d(d<0);
   m = mean(dn);
   s = std(dn);
   wt = 1 ./ (1 + exp( 2*(d - (2*s - m))/s ) );
   if (norm(w-wt)/norm(w) < ratio) || (count<maxiter)
      break;
   end
   w = wt;
   count = count + 1;
end