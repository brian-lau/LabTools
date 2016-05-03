Fs = 2000;
T = 20;

[s,f,Sx0] = fakeLFP2(Fs,T,true);

[west, Aest, Cest, SBC, FPE, th] = arfit(s.values{1},1,1);
[siglev,x_] = arres(west,Aest,s.values{1},2);

hbw = 0.25;
% Raw PSD
px = sig.mtspectrum(s.values{1},'hbw',hbw,'f',f,'Fs',Fs);
% PSD of AR(1) whitened signal
[px_,params] = sig.mtspectrum(x_,'hbw',hbw,'f',f,'Fs',Fs,'quadratic',0);

% Estimate baseline
bl = stat.baseline.arpls(px_.P,1e7);

px_bl = px_.P - bl + mean(bl);
%px_bl = px_.P - bl;
%px_bl = px_bl - min(px_bl);
alpha = params.k;
Q = gaminv(.05,alpha,1/alpha) / (quantile(px_bl,.05));

figure;
subplot(321); hold on
plot(f,px.P);
plot(f,Sx0);
%plot(f,px0_true-bl);
subplot(322); hold on
plot(f,10*log10(px.P));
plot(f,10*log10(Sx0));
%plot(f,10*log10(px0_true-bl));
set(gca,'xscale','log');

subplot(323); hold on
plot(f,px_.P);
plot(f,bl);
subplot(324); hold on
plot(f,10*log10(px_.P));
plot(f,10*log10(bl));
set(gca,'xscale','log'); axis tight;
subplot(325); hold on
plot(f,px_.P-bl);
subplot(326); hold on
plot(f,px_.P-bl);
set(gca,'xscale','log'); axis tight;

figure; hold on
plot(f,px_bl*Q);
p = [.05 .5 .95 .99 .999 .9999];
for i = 1:numel(p)
   c = gaminv(p(i),alpha,1/alpha);
   plot([0.1 Fs/2],[c c],'-','Color',[1 0 0 0.25]);
   text(Fs/2,c,sprintf('%1.6f',p(i)));
end
plot([0.1 Fs/2],[median(px_bl*Q) median(px_bl*Q)],'-')
