s = SampledProcess(randn(5000,3),'Fs',1000,'deferredEval',true);
detrend(s);
s.lowpass('Fstop',50,'Fpass',10);
s.resample(500);
s.map(@(x) abs(x) + 1);
setWindow(s,[1 2]);
setOffset(s,-1);

s.queue
% note that the last column indicates whether row was evaluated
plot(s,'stack',true)
run(s);
plot(s,'stack',true)
s.queue

s(1) = SampledProcess(randn(1000,3),'Fs',1000,'deferredEval',true);
s(2) = SampledProcess(randn(1000,3),'Fs',1000,'deferredEval',true);
detrend(s);
s.map(@(x) x + 1);
setWindow(s,[.25 .75]);
setOffset(s,-.25);
s.lowpass('Fstop',100,'Fpass',10);
s.resample(500);

s(1) = SampledProcess(randn(1000,3),'Fs',1000,'deferredEval',true);
s(2) = SampledProcess(randn(1000,3),'Fs',1000,'deferredEval',true);
s.highpass('Fstop',1,'Fpass',10);
