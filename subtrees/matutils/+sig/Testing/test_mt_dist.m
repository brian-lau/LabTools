clear all;
rng(12312);
Fs = 1024;
dt = 1/Fs;
t = (0:50000)'*dt;

x = randn(size(t));
f = [];
%f = [2:50:500];
for i = 1:numel(f)
   x = x + (.25/numel(f))*cos(2*pi*f(i)*t);
end
 
x = 10*randn(size(t));

nw = 9;

%% Check that we can reproduce pmtm output when nfft=signal length
tic;[out,params] = sig.mtspectrum(x,'thbw',nw,'nfft',numel(x),'Fs',Fs,'quadratic',1);toc

figure;
xx = 0:.1:50;
subplot(211);
plot(xx,chi2pdf(xx,2*params.k));
subplot(212);
n = histc(out.P*(2*params.k/mean(out.P)),[0:1:100]);
bar([0:1:100],n./sum(n),'histc');
hold on
plot(xx,chi2pdf(xx,2*params.k),'r');
axis([0 100 get(gca,'ylim')])

sum(out.P*(2*params.k/mean(out.P)) > 100)

Q = gaminv(.05,params.k,1/(params.k)) / (quantile(out.P,.05))
%Q = gaminv(.05,params.k,1/params.k) / (quantile(out.P/(2*params.k),.05) * 2*params.k)

figure; hold on

plot(out.f,out.P*Q)
for i = 1:numel(f)
   plot([f(i) f(i)], get(gca,'ylim'),'--','Color',[1 0 0 0.5]);
end

p = [.05 .5 .95 .99 .999 .9999 .99999 .999999];
for i = 1:numel(p)
   c = gaminv(p(i),params.k,1/params.k);
   plot([0 500],[c c],':','Color',[1 0 0 0.5]);
   text(500,c,sprintf('%1.6f',p(i)));
end