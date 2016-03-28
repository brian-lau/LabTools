[s,artifacts,f,Sx] = fakeLFP(2000,10,[2 2 2 2]);

h = plot(s);
plot(artifacts,'handle',h,'overlap',.1,'stagger',true);
close

step = 1;
win = [s.tStart:step:s.tEnd]';
win = [win,win+step];
win(win>s.tEnd) = s.tEnd;
s.window = win;

hbw = 2.5;

tic; p = s.psd('f',f,'hbw',hbw,'robust','huber');toc
plot(p);
subplot(211); hold on
plot(f,10*log10(Sx));
subplot(212); hold on
plot(f,10*log10(Sx));

X = s.values;
tic;[out,par] = sig.mtspectrum(X,'hbw',hbw,'Fs',s.Fs,'f',f,...
   'quadratic',1,'robust','huber');toc
subplot(211)
plot(out.f,10*log10(out.P(:,1)),'-')
subplot(212)
plot(out.f,10*log10(out.P(:,2)),'-')

% plot(p,'log',false);
% subplot(211); hold on
% plot(f,Sx);
% subplot(212); hold on
% plot(f,Sx);
% plot(out.f,out.P(:,2),'--')

p = s.reset().psd('f',f,'hbw',1);
p.plot();
subplot(211); hold on
plot(f,10*log10(Sx));
subplot(212); hold on
plot(f,10*log10(Sx));

plot(p,'log',false);
subplot(211); hold on
plot(f,Sx);
subplot(212); hold on
plot(f,Sx);

p = s.reset().psd('f',f,'method','welch','window',fix(step*s.Fs));
p.plot();
subplot(211); hold on
plot(f,10*log10(Sx));
subplot(212); hold on
plot(f,10*log10(Sx));

plot(p,'log',false);
subplot(211); hold on
plot(f,Sx);
subplot(212); hold on
plot(f,Sx);

s.reset();
win = artifacts.getWindow('eventType','Artifact','minDuration',.75);
s.window = win;
p = s.psd('f',f,'hbw',2.5,'robust','huber');
p.plot();
subplot(211); hold on
plot(f,10*log10(Sx));
subplot(212); hold on
plot(f,10*log10(Sx));

plot(p,'log',false);
subplot(211); hold on
plot(f,Sx);
subplot(212); hold on
plot(f,Sx);
