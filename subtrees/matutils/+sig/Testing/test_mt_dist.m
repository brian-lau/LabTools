clear all;
rng(12312);
Fs = 1024;
dt = 1/Fs;
t = (0:50000)'*dt;

x = randn(size(t));
%f = [];
f = [50:50:500];
for i = 1:numel(f)
   x = x + (.35/numel(f))*cos(2*pi*f(i)*t);
end

nw = 4;
tic;[out,params] = sig.mtspectrum(x,'thbw',nw,'nfft',numel(x),'Fs',Fs,'quadratic',1);toc

alpha = params.k;

figure;
xx = 0:.1:50;
subplot(211); hold on
% Eq 33 Das et al.
n = histc(out.P*(2*alpha/mean(out.P)),[0:1:100]);
bar([0:1:100],n./sum(n),'histc');
hold on
plot(xx,chi2pdf(xx,2*alpha),'r');
axis([0 100 get(gca,'ylim')])
xlabel('PSD values')
title('Multitaper PSD is central \chi^2_\nu distributed, with \nu \approx 2\timesK')
%sum(out.P*(2*params.k/mean(out.P)) > 100)

% Scale factor that matches 5% point of data to that of gamma distribution
% See Thompson et al., Thompson & Haley
Q = gaminv(.05,alpha,1/alpha) / (quantile(out.P,.05));

subplot(212); hold on
n = histc(out.P*Q,[0:.05:5]);
bar([0:.05:5],n./sum(n)/.05,'histc');
xx = 0:.05:5;
plot(xx,gampdf(xx,alpha,1/alpha),'r');
axis([0 5 get(gca,'ylim')])
xlabel('Standardized PSD values')
title('Standardized multitaper PSD is gamma distributed, with ')

figure; hold on
plot(out.f,out.P*Q)
for i = 1:numel(f)
   plot([f(i) f(i)], get(gca,'ylim'),'--','Color',[1 0 0 0.5]);
end

p = [.05 .5 .95 .99 .999 .9999 .99999 .999999];
for i = 1:numel(p)
   c = gaminv(p(i),alpha,1/alpha);
   plot([0 500],[c c],':','Color',[1 0 0 0.5]);
   text(500,c,sprintf('%1.6f',p(i)));
end