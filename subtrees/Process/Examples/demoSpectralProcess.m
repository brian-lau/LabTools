t = 0:0.001:2;                    % 2 secs @ 1kHz sample rate
y = chirp(t,100,1,200,'q');       % Start @ 100Hz, cross 200Hz at t=1sec
[s,f,t] = spectrogram(y,300,150,[],1E3,'yaxis');

tf = SpectralProcess('values',s','f',f,'tStep',.15,'tBlock',.3,'tEnd',2)

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


%load quadchirp;
%s = SampledProcess(quadchirp','Fs',1000);
t = [0:0.001:2]';                    % 2 secs @ 1kHz sample rate
s = SampledProcess(chirp(t,100,2,100,'q'),'Fs',1000);
tf = toSpectralProcess(s,'method','cwt','f',[.1 500]);
plot(tf);
plot(tf,'log',false);

tf = toSpectralProcess(s,'method','stft','tBlock',.1,'tStep',.02,'f',[.1:500]);
plot(tf);
plot(tf,'log',false);

tf = toSpectralProcess(s,'method','chronux','tBlock',.1,'tStep',.02,'f',[.1:500]);
plot(tf);
plot(tf,'log',false);

%%
load quadchirp;
s = SampledProcess(quadchirp','Fs',1000);
s.offset = -2;
tf = toSpectralProcess(s,'method','cwt','f',[.1 500]);
