% QKDE                       Quick and dirty kernel density estimate
% 
%     z = qkde(x,data,bw,flag)
%
%     Fast density estimation using convolution with a finite kernel. This 
%     can be much faster than exact KDE estimation (eg, ksdensity), but can 
%     introduce errors (typically, extremely small) due to the finite support 
%     of the kernel (eg, a gaussian kernel is truncated at 4 SDs).
%
%     INPUTS
%     x    - grid over which to estimate density
%     data - vector of data
%     bw   - bandwidth
%  
%     OPTIONAL
%     dt   - grid stepsize
%     flag - string indicating kernel type:
%             't' : Triangular
%             'e' : Epanechnikov
%             'g' : Gaussian (default)
%             'b' : Boxcar
%  
%     OUTPUTS
%     z    - density estimate
%
%     SEE ALSO
%     kernel

%     $ Copyright (C) 2006-2012 Brian Lau http://www.subcortex.net/ $
%
%     REVISION HISTORY:
%     brian 03.01.06 written
%     brian 11.10.12 use conv 'same' option
%

% TODO
% x create persistent variable for kernel, slower
% x check fft speed, slower for short kernels

function z = qkde(x,data,bw,dt,flag)

if nargin < 5
   flag = 'g'; % gaussian
end
if nargin < 4
   dt = 1;
end

g = kernel(bw,dt,flag);
y = histc(data,x);

% For short kernels, convolution in the time-domain is faster
z = conv(y,g,'same');

% [g,t] = kernel(bw,flag);
% z = conv(g,y);
% hw = floor(length(t)/2);
% z = z(hw+1:end-hw);
