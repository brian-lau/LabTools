function t = tvec(t0,dt,n)

assert(isscalar(t0),'SampledProcess:tvec:InputFormat');
assert(isscalar(dt),'SampledProcess:tvec:InputFormat');
assert(isscalar(n),'SampledProcess:tvec:InputFormat');

t = t0 + (0:dt:(dt*(n-1)))';
