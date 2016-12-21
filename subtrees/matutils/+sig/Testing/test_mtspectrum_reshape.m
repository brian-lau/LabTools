clear all;
Fs = 1024;
dt = 1/Fs;
t = (0:92047)'*dt;

x = cos(2*pi*250*t) + .5*cos(2*pi*50*t) + 5*randn(size(t));

nw = 4.5;

% Check that we're calculating F-statistic correctly
[Fval,A,f,signal,sd] = ftestc(x,struct('tapers',[nw 8],'Fs',Fs),[],'n');
[out,par] = sig.mtspectrum(x,'thbw',nw,'f',f,'Fs',Fs,'Ftest',true);

% F-values match
figure;
subplot(211); hold on
plot(f,Fval);
plot(out.f,out.Fval);
subplot(212);
plot(f,Fval-out.Fval);

% Amplitudes match
figure;
subplot(211); hold on
plot(f,abs(A));
plot(out.f,abs(out.A));
subplot(212);
plot(f,abs(A)-abs(out.A));

data = rmlinesc(x,struct('tapers',[4.5 8],'Fs',Fs),[],'y',[50 250]);

%
data = rmlinesc(x,struct('tapers',[4.5 8],'Fs',Fs),[],'y',[50 250]);

clear all;
[s,artifacts,f,Sx] = fakeLFP(2000,5,[2 2 2 2]);
Fs = 2000;
dt = 1/Fs;

x = s.values{1}(:,1) + 5*cos(2*pi*50*s.times{1}) + 10*cos(2*pi*300*s.times{1});
x = [x,s.values{1}(:,1)];


data = rmlinesc(x,struct('tapers',[4.5 8],'Fs',Fs),[],'y',[50 300]);

[out,par] = sig.mtspectrum(x,'hbw',.75,'f',0:.01:1000,'Fs',s.Fs,'Ftest',true);

%
x = data.values{1}(1:10000,6);

d = rmlinesc(x,struct('tapers',[4.5 8],'Fs',data.Fs),[],'y',[50]);
