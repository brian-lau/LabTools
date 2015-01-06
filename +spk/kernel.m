% KERNEL                     Kernels for 1-D density estimation
% 
%     [g,t] = kernel(bw,flag)
%
%     These kernels have finite support to allow for fast KDE estimation
%     via convolution.
%
%     INPUTS
%     bw   - kernel parameters
%     dt   - grid stepsize
%     flag - string indicating kernel type:
%             Gaussian (default) : 'g' , 'gauss' , 'gaussian' 'normal'
%                     Triangular : 't' , 'tria' , 'triangle'
%                   Epanechnikov : 'e' , 'epan' , 'epanechnikov'
%                    Exponential : 'exp' , 'exponential'
%                         Boxcar : 'b' , 'box' , 'boxcar'
%  
%     OUTPUTS
%     g    - kernel
%     t    - support
%
%     SEE ALSO
%     qkde
%
%     REFERENCE
%     Table 1 from Nawrot et al. 1999. Single-trial estimation of neuronal 
%     firing rates: from single-neuron spike trains to population activity
%     J Neurosci Methods 94, 81-92.
%

%     $ Copyright (C) 2006-2012 Brian Lau http://www.subcortex.net/ $
%
%     REVISION HISTORY:
%     brian 03.01.06 written

% TODO
% causal kernels a la Schall et al.

function [g,t] = kernel(bw,dt,flag)

if nargin < 3
   flag = 'g';
end

if nargin < 2
   dt = 1;
end

switch lower(flag)
   case {'g','gauss','gaussian','normal'}
      sd = 4;
      t = -(sd*bw):dt:(sd*bw);
      g = exp(-0.5*(t./bw).^2) ./ (sqrt(2*pi)*bw);
   case {'t','tria','triangle'}
      r6 = sqrt(6);
      t = -(r6*bw):dt:(r6*bw);
      g = (1/(6*bw^2))*(r6*bw - abs(t));
   case {'e','epan','epanechnikov'}
      r5 = sqrt(5);
      t = -(r5*bw):dt:(r5*bw);
      g = (3/(4*r5*bw))*(1 - t.^2./(5*bw^2));
   case {'exp','exponential'}
      t = -(5*bw):dt:(5*bw);
      g = exp(-sqrt(2).*abs(t./bw)) ./ (sqrt(2)*bw);
   case {'b','box','boxcar'}
      r3 = sqrt(3);
      t = -(r3*bw):dt:(r3*bw);
      g = zeros(size(t));
      g(:) = 1./(2*r3*bw);
   otherwise
      error('Unknown kernel type in KERNEL!')
end

g = g*dt;
