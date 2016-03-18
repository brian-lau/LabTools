
Fs = 1000;
dt = 1/Fs;
t = (0:dt:20)';
x = cos(2*pi*30*t) + randn(size(t));

nw = 30;

s = SampledProcess(x,'Fs',Fs);

tic;obj = psd(s,'f',1:.25:400,'nw',nw);toc

s2 = new(s);
win = [0:1000:19000]';
win = [win , win+1000]./Fs;
s2.window = win;

tic;obj2 = psd(s2,'f',1:.25:400,'nw',nw);toc

figure; hold on
plot(obj.values{1});
plot(obj2.values{1});


%%
clear all
Fs = 2000; % sampling frequency
T = 20000;

% PAC signal 1
f1 = 20 / Fs;
f2 = 250 / Fs;
e1 = cos(2 * pi * f1 * (1:T) + 0.1 * cumsum(randn(1, T)));
e2 = exp(-2*e1) .* cos(2 * pi * f2 * (1:T)) / 4;
x = e1 + e2;
x1 = x(:);

nw = 10;

s = SampledProcess(x1,'Fs',Fs);

tic;obj = psd(s,'f',1:.25:400,'nw',nw);toc

s2 = new(s);
win = [0:5000:20000]';
win = [win , win+5000]./Fs;
s2.window = win;

tic;obj2 = psd(s2,'f',1:.25:400,'nw',nw);toc

figure; hold on
plot(obj.values{1});
plot(obj2.values{1});
