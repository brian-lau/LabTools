function t = tvec(t0,tWinstep,n)

assert(isscalar(t0),'SpectralProcess:tvec:InputFormat');
assert(isscalar(tWinstep),'SpectralProcess:tvec:InputFormat');
assert(isscalar(n),'SpectralProcess:tvec:InputFormat');

t = t0 + (0:tWinstep:(tWinstep*(n-1)))';
