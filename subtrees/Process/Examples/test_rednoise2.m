Fs = 2000;
T = 10;

for i = 1:1
   i
   [s,f,Sx0] = fakeLFP2(Fs,T,1);
   S = Spectrum('input',s);
   S.psdParams.f = 0:.25:1000;
   S.psdParams.hbw = 0.5;
   S.run;
   
   psd{i} = S.psdWhite.values{1};
   [~,fa{i}] = S.threshold(.01);
end

S.plotDiagnostics;
S.plot

%%%
Fs = 2000;
T = 30;
[s,f,Sx0] = fakeLFP2(Fs,T,0);

step = 2;
win = [s.tStart:step:s.tEnd]';
win = [win,win+step];
win(win>s.tEnd) = s.tEnd;
s.window = win;


S = Spectrum('input',s);
S.psdParams.f = 0:.25:1000;
S.psdParams.hbw = 1;
S.run;

hbw = 1;
x = s.values;
tic;[out,params] = sig.mtspectrum(x,'hbw',hbw,'f',0:.5:500,'Fs',Fs);toc

alpha = mean(params.k);

figure;
xx = 0:.1:50;
subplot(211); hold on
% Eq 33 Das et al.
n = histc(out.P*(7.5*2*alpha/mean(out.P)),[0:1:100]);
bar([0:1:100],n./sum(n),'histc');
hold on
plot(xx,chi2pdf(xx,2*alpha),'r');
axis([0 100 get(gca,'ylim')])
xlabel('PSD values')
title('Multitaper PSD is central \chi^2_\nu distributed, with \nu \approx 2\timesK')
%sum(out.P*(2*params.k/mean(out.P)) > 100)
