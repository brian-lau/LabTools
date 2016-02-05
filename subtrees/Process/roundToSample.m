function y = roundToSample(x,dt)

assert(isscalar(dt),'dt must be scalar');
y = round(x/dt)*dt;
