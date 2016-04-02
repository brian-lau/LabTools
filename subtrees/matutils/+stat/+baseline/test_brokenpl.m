Fs = 1000;
T = 20;
s = fakeLFP2(Fs,T,2);

f = 0:.25:500;
q = 0;
Fs = 1000;
nw = 4;

import stat.baseline.*

[px,params] = sig.mtspectrum(s.values{1},'thbw',nw,'f',f,'Fs',Fs,'quadratic',q);

p = px.P(2:end);
f = px.f(2:end);
%fun = @(b) log(brokenpl(b,f)) - log(p);
fun = @(b) asymwt(log(brokenpl(b,f)),log(p));

b0 = [1 1 0 1 40];
beta = lsqnonlin(fun,b0,[0 0 0 0 0],[inf 3 5 5 500])

z = p./brokenpl(beta,f);

figure; 
subplot(311); hold on
plot(f,brokenpl(beta,f));
plot(f,p);
set(gca,'xscale','log');
set(gca,'yscale','log');

subplot(312); hold on
plot(f,z);
pmed = smooth(z,1001,'rlowess');
plot(f,pmed);

subplot(313);
plot(f,z./pmed);