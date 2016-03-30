clear sig;
%h = 1.1:.1:2.9;
h = 1.1:.05:1.9;
x = Da;%s.values{1};%
f = 0:.25:250;
q = 0;
Fs = 1000;
nw = 2.5;

[px,params] = sig.mtspectrum(x,'thbw',nw,'f',f,'Fs',Fs,'quadratic',q);

pmed = sig.irasa(x,f,q,Fs,2*nw);


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
Fs = 2000;
T = 20;
[s,f,Sx0] = fakeLFP2(Fs,T,1);
spec = amri_sig_fractal(s.values{1},Fs,'frange',[1 500]);