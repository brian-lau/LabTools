[s,artifacts,f,Sx] = fakeLFP(2000,20,[2 2 2 2]);

h = plot(s);
plot(artifacts,'handle',h,'overlap',.1,'stagger',true);
close

step = 1;
win = [s.tStart:step:s.tEnd]';
win = [win,win+step];
win(win>s.tEnd) = s.tEnd;
s.window = win;

p = s.psd('f',f,'hbw',2.5,'robust','huber');
plot(p);
subplot(211); hold on
plot(f,10*log10(Sx));
subplot(212); hold on
plot(f,10*log10(Sx));

plot(p,'log',false);
subplot(211); hold on
plot(f,Sx);
subplot(212); hold on
plot(f,Sx);

p = s.reset().psd('f',f,'hbw',2.5,'hbw',2);
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
