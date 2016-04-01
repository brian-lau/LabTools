clear sig;
%h = 1.1:.1:2.9;
h = 1.1:.05:1.9;
x = s.values{1};%Da;%
f = 0:.25:500;
q = 0;
Fs = 1000;
nw = 4;

[px,params] = sig.mtspectrum(x,'thbw',nw,'f',f,'Fs',Fs,'quadratic',q);

pmed = sig.irasa(x,f,q,Fs,nw);

z = px.P./(1./px.f);
pmed2 = smooth(z,57,'rlowess');

ind = (f>4) & (f<35);
opts = fitoptions('Method','SmoothingSpline','SmoothingParam',0.1);
[pmed3, goodness, output] = fit(px.f,pmed,'smoothingspline',opts);

figure;
subplot(311);
plot(spec.freq,10*log10(spec.mixd),'r'); hold on;
plot(px.f,10*log10(px.P))
set(gca,'xscale','log');
subplot(312);
plot(spec.freq,10*log10(spec.frac),'r'); hold on;
plot(px.f,10*log10(pmed))
set(gca,'xscale','log');
subplot(313);
plot(spec.freq,spec.mixd./spec.frac,'r'); hold on;
plot(px.f,(px.P./pmed))
%set(gca,'yscale','log');

% %%
Fs = 1000;
T = 20;
[s,f,Sx0] = fakeLFP2(Fs,T,2);
spec = amri_sig_fractal(s.values{1},Fs,'frange',[1 500]);