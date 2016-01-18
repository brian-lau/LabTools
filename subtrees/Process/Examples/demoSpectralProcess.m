t = 0:0.001:2;                    % 2 secs @ 1kHz sample rate
y = chirp(t,100,1,200,'q');       % Start @ 100Hz, cross 200Hz at t=1sec
[s,f,t] = spectrogram(y,300,150,[],1E3,'yaxis');

tf = SpectralProcess('values',s','f',f,'tStep',.15,'tBlock',.3,'tEnd',2)

temp = cat(3,s',s');
%temp = cat(4,temp,temp);
tf = SpectralProcess('values',temp,'f',f,'tStep',.15,'tBlock',.3,'tEnd',2)

temp = cat(3,s',s');
temp = mean(temp);
tf = SpectralProcess('values',temp,'f',f,'tStep',.15,'tBlock',.3)

t = [0:0.001:2]';                    % 2 secs @ 1kHz sample rate
y(:,1) = chirp(t,100,1,100,'q');       % Start @ 100Hz, cross 200Hz at t=1sec
y(:,2) = chirp(t,100,1,200,'q');       % Start @ 100Hz, cross 200Hz at t=1sec
y(:,3) = chirp(t,100,1,300,'q');       % Start @ 100Hz, cross 200Hz at t=1sec

s = SampledProcess(y,'Fs',1000);
