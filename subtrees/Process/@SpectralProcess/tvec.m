function t = tvec(t0,tStep,n)

assert(isscalar(t0),'SampledProcess:tvec:InputFormat','1st input must be scalar');
assert(isscalar(tStep),'SampledProcess:tvec:InputFormat','2nd input must be scalar');
assert(isscalar(n),'SampledProcess:tvec:InputFormat','3rd input must be scalar');

t = t0 + (0:tStep:(tStep*(n-1)))';
