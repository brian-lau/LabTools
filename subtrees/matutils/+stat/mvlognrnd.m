% MVLOGNRND - Multivariate lognormal random numbers
%
%     [r,sigma] = mvlognrnd(mu,sigma,cases)
%     
%     Returns an array of random numbers generated from the lognormal 
%     distribution with parameters MU and SIGMA. *Unlike* LOGNRND, MU and 
%     SIGMA are the mean and covariance matrix of the lognormal distribution. 
%     
% INPUTS
%     mu    - [1 x d] lognormal means
%     sigma - [d x d] covariance matrix for lognormal
%     cases - scalar, number of multivariate draws
%
% OUTPUTS
%     r     - [cases x d] lognormal random numbers
%     sigma - [d x d] covariance matrix for lognormal
%
% REFERENCES
%     Zerovnik G, Trkov A, Smith DL, Capote R (2013). Transformation of 
%     correlation coefficients between normal and lognormal distribution 
%     and implications for nuclear applications.
%     Nuclear Instruments and Methods in Physics Research A, 727, 33-39
%
% EXAMPLE
%     mu = [15 30]
%     sigma = [1 1.5;1.5 3]
%     [r,sigma2] = mvlognrnd(mu,sigma,1e6);
%     mean(r)
%     cov(r)
%     corr(r)
%
%     % Desired correlation
%     [~,expC] = cov2corr(sigma)
%
%     % Specifying correlation rather than covariance
%     mu = [5 10]
%     std_x = [1 3];
%     C = [1 -.5;-.5 1];
%     cov_x = C.*(std_x'*std_x)
%     [r,sigma2] = mvlognrnd(mu,cov_x,1e6);
%     mean(r)
%     cov(r)
%     corr(r)

%     $ Copyright (C) 2017 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/matutils


function [r,sigma] = mvlognrnd(mu,sigma,cases)

mu = mu(:)';
mumu = mu'*mu;

% Check theoretical bounds on covariance/correlation
var_x = diag(sigma)';
temp = sqrt( log1p(var_x./mu.^2)'*log1p(var_x./mu.^2) );
sigma_LB = mumu.*( exp(-temp) - 1 );
%C_LB = sigma_LB ./ (sqrt(var_x)'*sqrt(var_x));
ind = sigma < sigma_LB;
if any(ind(:))
   warning('Covariance matrix supplied exceeds theoretical lower bound');
   sigma(ind) = sigma_LB(ind);
end
sigma_UB = mumu.*( exp(temp) - 1 );
%C_UB = sigma_UB ./ (sqrt(var_x)'*sqrt(var_x));
ind = sigma > sigma_UB;
if any(ind(:))
   warning('Covariance matrix supplied exceeds theoretical upper bound');
   sigma(ind) = sigma_UB(ind);
end

% Transform to normal space
sigma_y = log1p( sigma./mumu );
mu_y = log(mu) - diag(sigma_y)'./2;
y = mvnrnd(mu_y,sigma_y,cases);

% Back into lognormal
r = exp(y);

