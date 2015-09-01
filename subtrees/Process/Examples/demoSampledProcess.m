%% Scalar SampledProcess
clear all;
x = repmat(cos(2*pi*(0:.001:1-.001))',1,3);
s = SampledProcess('values',x,'Fs',1000,'tStart',0);
plot(s);

%% Scalar SampledProcess with multiple signals
clear
% signals sampled at same Fs, tStart, numel
dt = 0.00001;
x(:,1) = cos(2*pi*(0:dt:(1-dt)))';
x(:,2) = cos(2*pi*(0:dt:(1-dt))+pi/2)';
x(:,3) = cos(2*pi*(0:dt:(1-dt))+pi)';
s = SampledProcess('values',x,'Fs',1/dt,'tStart',0);
plot(s);

%% Vector SampledProcess
clear
x = cos(2*pi*(0:.001:1-.001))';
s(1) = SampledProcess('values',x,'Fs',1000,'tStart',0);
x = cos(2*pi*(0:.001:.5-.001)+pi/2)';
s(2) = SampledProcess('values',x,'Fs',1000,'tStart',0);
plot(s);

%% ALIGNMENT
clear
% Two times series, one with delta at t=50, another with delta at t=25
Fs = 1;
x = zeros(101,1);
x(51) = 1;
s(1) = SampledProcess('values',x,'Fs',Fs,'tStart',0);
x = zeros(51,1);
x(26) = 1;
s(2) = SampledProcess('values',x,'Fs',Fs,'tStart',0);
plot(s);

% Manually synchronize to the peak, slightly awkward
window = [-10 10]./Fs;
offset = [50 25]./Fs;
% Window around the peak
s.setWindow({window+offset(1) window+offset(2)});
% then shift relative to the peak
s.setOffset(-offset);
plot(s);

% Export if needed
[times,values] = arrayfun(@(x) deal(x.times{1},x.values{1}),s,'uni',false);

% Synchronize through method
s.reset();
s.sync(offset,'window',window);
plot(s);

%% Interpolation when synchronizing
clear
x = [0 0 .5];
s(1) = SampledProcess('values',x);
x = [0 1 0];
s(2) = SampledProcess('values',x);
plot(s)

window = [-2 2];
offset = [1.9 0.5];
sync(s,offset,'window',window);
plot(s);

%% 
% signals sampled at same Fs, tStart, numel
clear all;
dt = 0.00001;
x(:,1) = cos(2*pi*(0:dt:(1-dt)))';
x(:,2) = cos(2*pi*(0:dt:(1-dt))+pi/2)';
x(:,3) = cos(2*pi*(0:dt:(1-dt))+pi)';
s(1) = SampledProcess('values',x(:,1),'Fs',1/dt,'tStart',0);
s(2) = SampledProcess('values',x(:,2),'Fs',1/dt,'tStart',0);
s(3) = SampledProcess('values',x(:,3),'Fs',1/dt,'tStart',0);
plot(s);

% synchronize to trough of sinusoid
window = [-2 2];
offset = [0.5 .25 1];
sync(s,offset,'window',window);
plot(s);

% Generate a sine wave at the expected phase
t0 = -2;
n = numel(s(1).times{1});
t = t0 + (0:dt:(dt*(n-1)))';
w = cos(2*pi*t + pi)';

% maximum absolute difference where signals have support
arrayfun(@(x) max(abs(w - x.values{1}')),s)

%%
clear
% signals sampled at same Fs, different tStart
dt = 0.00001;
x = cos(2*pi*(0:dt:(1-dt)))';
s(1) = SampledProcess('values',[x,0.5*x],'Fs',1/dt,'tStart',0);
x = cos(2*pi*(-1:dt:(1-dt))+pi/2)';
s(2) = SampledProcess('values',[x,0.5*x],'Fs',1/dt,'tStart',-1);
x = cos(2*pi*(-2:dt:(1-dt))+pi)';
s(3) = SampledProcess('values',[x,0.5*x],'Fs',1/dt,'tStart',-2);
plot(s);

% synchronize to trough of sinusoid
window = [-2 2];
offset = [0.5 .25 1];
sync(s,offset,'window',window);
plot(s);

% Generate a sine wave at the expected phase
t0 = -2;
n = numel(s(1).times{1});
t = t0 + (0:dt:(dt*(n-1)))';
w = cos(2*pi*t + pi)';

% maximum absolute difference where signals have support
arrayfun(@(x) max(abs(w - x.values{1}(:,1)')),s)

%%
clear
% signals sampled at different Fs, tStart, numel
dt = 0.00001;
x = cos(2*pi*(0:dt:(1-dt)))';
s(1) = SampledProcess('values',x,'Fs',1/dt,'tStart',0);
dt = 0.0001;
x = cos(2*pi*(0:dt:(1-dt))+pi/2)';
s(2) = SampledProcess('values',x,'Fs',1/dt,'tStart',0);
dt = 0.01;
x = cos(2*pi*(0:dt:(1-dt))+pi)';
s(3) = SampledProcess('values',x,'Fs',1/dt,'tStart',0);
plot(s);

% synchronize to trough of sinusoid
window = [-2 2];
offset = [0.5 .25 1];
sync(s,offset,'window',window);
plot(s);
