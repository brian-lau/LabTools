t = 0:0.001:2;                    % 2 secs @ 1kHz sample rate
y = chirp(t,100,1,200,'q');       % Start @ 100Hz, cross 200Hz at t=1sec
[s,f,t] = spectrogram(y,300,150,[],1E3,'yaxis');

tf = SpectralProcess('values',s','f',f,'tStep',.15,'tBlock',.3,'tEnd',2);

temp = cat(3,s',s');
temp = cat(4,temp,temp);
tf = SpectralProcess('values',temp,'f',f,'tStep',.15,'tBlock',.3,'tEnd',2)

temp = cat(3,s',s');
temp = mean(temp);
tf = SpectralProcess('values',temp,'f',f,'tStep',.15,'tBlock',.3)

t = [0:0.001:2]';                    % 2 secs @ 1kHz sample rate
y(:,1) = chirp(t,10,2,200,'q');       % Start @ 100Hz, cross 100Hz at t=1sec
y(:,2) = chirp(t,100,1,200,'q');       % Start @ 100Hz, cross 200Hz at t=1sec
y(:,3) = chirp(t,1,2,300,'q');       % Start @ 1Hz, cross 300Hz at t=2sec

s = SampledProcess(y,'Fs',1000);

y1 = chirp([0:0.0001:2]',1,2,20,'q');       % Start @ 100Hz, cross 100Hz at t=1sec
y2 = chirp([0:0.001:2]',1,2,20,'q');       % Start @ 100Hz, cross 200Hz at t=1sec
y3 = chirp([0:0.005:2]',1,2,20,'q');       % Start @ 1Hz, cross 300Hz at t=2sec

s(1) = SampledProcess(y1,'Fs',1/.0001);
s(2) = SampledProcess(y2,'Fs',1/.001);
s(3) = SampledProcess(y3,'Fs',1/.005);


%load quadchirp;
%s = SampledProcess(quadchirp','Fs',1000);
t = [0:0.001:2]';                    % 2 secs @ 1kHz sample rate
s = SampledProcess(chirp(t,100,2,100,'q'),'Fs',1000);
tf = tfr(s,'method','cwt','f',[.1 500]);
plot(tf);
plot(tf,'log',false);

tf = tfr(s,'method','stft','tBlock',.1,'tStep',.02,'f',[.1:500]);
plot(tf);
plot(tf,'log',false);

tf = tfr(s,'method','chronux','tBlock',.1,'tStep',.02,'f',[.1:500]);
plot(tf);
plot(tf,'log',false);

%%
load quadchirp;
s = SampledProcess(quadchirp','Fs',1000);
s.offset = -2;
tf = tfr(s,'method','cwt','f',[.1 500]);
plot(tf,'log',false);

%% Example calls to different TFR methods
t = [0:0.001:2]';                    % 2 secs @ 1kHz sample rate
y1 = chirp(t,10,2,10,'q');
y2 = chirp(t,60,2,60,'q');
s = SampledProcess([y1*.25;y1+y2],'Fs',1000);
s.setOffset(-2);

tf(1) = tfr(s,'method','stft','f',1:100,'tBlock',.5,'tStep',.05);
tf(2) = tfr(s,'method','multitaper','f',1:100,'tBlock',.5,'tStep',.05,'tapers',[2 3]);
tf(3) = tfr(s,'method','cwt','f',[1 100],'padmode','sym');
tf(4) = tfr(s,'method','stockwell','f',[1 100],'params',.5,'pad',200,'padmode','sym','decimate',4);
plot(tf,'log',false);

%%
t = [0:0.001:2]';                    % 2 secs @ 1kHz sample rate
y1 = chirp(t,100,2,100,'q');
y2 = chirp(t,200,2,200,'q');
s = SampledProcess([y1;y1+y2],'Fs',1000);
s.offset = -2;
tf = tfr(s,'method','cwt','f',[.1 500]);


t = [0:0.001:2]';                    % 2 secs @ 1kHz sample rate
y1 = chirp(t,10,2,10,'q');
y2 = chirp(t,60,2,60,'q');
s(1) = SampledProcess([y1;y1+y2],'Fs',1000);
s(2) = SampledProcess([y1*.25;y1+y2],'Fs',1000);
s.setOffset(-2);
tf = tfr(s,'method','stft','f',1:100,'tBlock',.5,'tStep',.05);
tf(3) = tfr(s(1),'method','cwt','f',[1 100]);
plot(tf,'log',false);
tf.normalize(0,'window',[-1.75 -1.],'method','subtract');
plot(tf,'log',false);


dt = 1/2048;
t = 0:dt:1;                    % 2 secs @ 1kHz sample rate
y = chirp(t,100,1,200,'q')';       % Start @ 100Hz, cross 200Hz at t=1sec

s = SampledProcess('values',y,'Fs',1/dt);

tf = tfr(s,'tBlock',0.5,'tStep',0.5,'f',[0:200])

tf = tfr(s,'method','stft','tBlock',0.5,'tStep',0.5,'f',[0:200])

