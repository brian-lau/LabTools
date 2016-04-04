clear all;
Fs = 1024;
dt = 1/Fs;
t = (0:92047)'*dt;

x = cos(2*pi*250*t) + .5*cos(2*pi*50*t) + 8*randn(size(t));

nw = 4.5;

%% Check that we can reproduce pmtm output when nfft=signal length
tic;[spec,freq] = pmtm(repmat(x,1,6),nw,numel(x),Fs);toc
tic;out = sig.mtspectrum(repmat(x,1,6),'thbw',nw,'nfft',numel(x),'Fs',Fs,'quadratic',false);toc

figure;
subplot(311); hold on
plot(freq,spec);
plot(out.f,out.P);
subplot(312); hold on
plot(freq,10*log10(spec));
plot(out.f,10*log10(out.P));
subplot(313);
plot(out.f,spec(1:numel(out.f),:)-out.P)

%% Check that we can reproduce pmtm output when f = requested vector
tic;[spec,freq] = pmtm(x,nw,0:.0125:Fs/2,Fs);toc
tic;out = sig.mtspectrum(x,'thbw',nw,'f',0:.0125:Fs/2,'Fs',Fs,'quadratic',false);toc

figure;
subplot(311); hold on
plot(freq,spec);
plot(out.f,out.P);
subplot(312); hold on
plot(freq,10*log10(spec));
plot(out.f,10*log10(out.P));
subplot(313);
plot(out.f,spec(1:numel(out.f))'-out.P)

%% Compare standard multitaper with Prieto's implementation of quadratic debiasing
%% some minor differences expected due to slightly different convergence algorithm
%% for Thompson's adaptive weights
tic;[spec,freq] = pmtm(x,nw,numel(x),Fs);toc
tic;[freq1,spec1] = mtspec(dt,x,nw,2*nw-1,1);toc
tic;out = sig.mtspectrum(x,'thbw',nw,'nfft',numel(x),'Fs',Fs,'quadratic',true);toc

figure;
subplot(211); hold on
plot(freq,spec);
plot(freq1,spec1);
plot(out.f,out.P);
subplot(212); hold on
plot(freq,10*log10(spec));
plot(freq1,10*log10(spec1));
plot(out.f,10*log10(out.P));
 
%% Same as above for some more structured signals
[s,artifacts,f,Sx] = fakeLFP(2000,20,[2 2 2 2]);
Fs = 2000;
dt = 1/Fs;

x = s.values{1}(:,1);

tic;[spec,freq] = pmtm(x,nw,[],Fs);toc
tic;[freq1,spec1] = mtspec(dt,x,nw,2*nw-1,1);toc
tic;out = sig.mtspectrum(x,'thbw',nw,'Fs',Fs,'quadratic',true);toc

figure;
subplot(211); hold on
plot(freq,spec);
plot(freq1,spec1);
plot(out.f,out.P);
subplot(212); hold on
plot(freq,10*log10(spec));
plot(freq1,10*log10(spec1));
plot(out.f,10*log10(out.P));
 

