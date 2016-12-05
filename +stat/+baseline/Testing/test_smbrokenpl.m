% Test fitting a smoothly broken power law to spectrum

clear all;
rng(1111234);
Fs = 1000;
T = 20;
s = fakeLFP2(Fs,T,1);

f = 0:.25:500;
q = 0;
Fs = 1000;
nw = 4;

import stat.baseline.*

[px,params] = sig.mtspectrum(s.values{1},'thbw',nw,'f',f,'Fs',Fs,'quadratic',q);

% Ignore DC
p = px.P(2:end);
f = px.f(2:end);

% Set up function handle for fitting
%fun = @(b) log(smbrokenpl(b,f)) - log(p);
fun = @(b) asymwt(log(smbrokenpl(b,f)),log(p));

b0 = [1 1 0 1 40];
beta = lsqnonlin(fun,b0,[0 0 0 0 0],[inf 3 5 5 500]);

% post-whitened spectrum
z = p./smbrokenpl(beta,f);

figure; 
subplot(311); hold on
plot(f,smbrokenpl(beta,f));
plot(f,p);
set(gca,'xscale','log');
set(gca,'yscale','log');

subplot(312); hold on
plot(f,z);
ps = smooth(z,1001,'rlowess');
plot(f,ps);

subplot(313);
plot(f,z./ps);