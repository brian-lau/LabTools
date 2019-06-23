% Check that we're calculating F-statistic correctly
clear all;
Fs = 1024;
dt = 1/Fs;
t = (0:92047)'*dt;

x = cos(2*pi*250*t) + .5*cos(2*pi*50*t) + 5*randn(size(t));
nw = 4.5;

% FTESTC comes from Chronux
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
plot(out.f,abs(par.A));
subplot(212);
plot(f,abs(A)-abs(par.A));

% Reshape spectrum removing line components
[outR,par] = sig.mtspectrum(x,'thbw',nw,'f',f,'Fs',Fs,...
   'reshape',true,'reshape_f',[50 250]);
% Chronux version
data = rmlinesc(x,struct('tapers',[nw 8],'Fs',Fs),[],'y',[50 250]);
% plot mtspectrum results in lower right subplot
subplot(3,2,6); hold on
plot(out.f,10*log10(out.P));
plot(outR.f,10*log10(outR.P));

%

%% Spectral reshaping within range, multiple channels
T = 5;
Fs = 2048;
s = fakeLFP2(Fs,T,6);
x = s.values{1}(:,1) + 5*cos(2*pi*49.25*s.times{1})+ 5*cos(2*pi*60.25*s.times{1});
x = [x , s.values{1}(:,1) + 2*cos(2*pi*50.5*s.times{1}) + 4*cos(2*pi*201.5*s.times{1})];

[out,par] = sig.mtspectrum(x,'hbw',.75,'f',0:.01:1000,'Fs',s.Fs,'Ftest',true,...
   'reshape',true,'reshape_f',[50 60 200],'reshape_hw',2,'reshape_nhbw',6,'reshape_threshold',0.0001);

hold on;
figure;
subplot(2,1,1); hold on
plot(out.f,10*log10(out.P_original(:,1)));
plot(out.f,10*log10(out.P(:,1)));
subplot(2,1,2); hold on
plot(out.f,10*log10(out.P_original(:,2)));
plot(out.f,10*log10(out.P(:,2)));


%% multiple sections, slightly different peak frequencies
clear all;
T = 5;
Fs = 2048;
s = fakeLFP2(Fs,T,6);

x{1} = s.values{1}(:,1) + 2*cos(2*pi*50*s.times{1}) + 2*cos(2*pi*200*s.times{1});
x{2} = s.values{1}(:,1) + 2*cos(2*pi*50.5*s.times{1}) + 2*cos(2*pi*201.5*s.times{1});
x{3} = s.values{1}(:,1) + 2*cos(2*pi*49.5*s.times{1}) + 2*cos(2*pi*199.5*s.times{1});
x{4} = s.values{1}(:,1);

[out,par] = sig.mtspectrum(x,'hbw',.75,'f',0:.01:1000,'Fs',s.Fs,'Ftest',true,...
   'reshape',true,'reshape_f',[50 200],'reshape_hw',2);

hold on;
%plot(out.f,10*log10(out.P_original(:,1)));
plot(out.f,10*log10(out.P(:,1)));
