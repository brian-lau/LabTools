clear sig;
h = 1.1:.05:1.9;
x = s.values{1};%Da;%
f = 0:.25:300;
q = 1;
Fs = 1000;
nw = 2.5;

[px,params] = sig.mtspectrum(x,'thbw',nw,'f',f,'Fs',Fs,'quadratic',q);

for i = 1:numel(h)
   [p,q] = rat(h(i));
   xh = resample(x,p,q);
   ph = sig.mtspectrum(xh,'thbw',nw,'f',f,'Fs',Fs,'quadratic',q);
   x1h = resample(x,q,p);
   p1h = sig.mtspectrum(x1h,'thbw',nw,'f',f,'Fs',Fs,'quadratic',q);
   
   pf(:,i) = sqrt(ph.P.*p1h.P);
end

pmed = median(pf,2);

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
set(gca,'yscale','log');

%%
Fs = 1000;
T = 20;
[s,f,Sx0] = fakeLFP2(Fs,T,1);
spec = amri_sig_fractal(s.values{1},Fs,'frange',[1 500]);