% Create a time vector given:
%   t0 - start time
%   dt - sample time (1/sampling frequency)
%   n  - # of samples

function t = tvec(t0,dt,n)

assert(isscalar(t0),'SampledProcess:tvec:InputFormat','1st input must be scalar');
assert(isscalar(dt),'SampledProcess:tvec:InputFormat','2nd input must be scalar');
assert(isscalar(n),'SampledProcess:tvec:InputFormat','3rd input must be scalar');

t = t0 + (0:dt:(dt*(n-1)))';
