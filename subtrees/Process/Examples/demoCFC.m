%%
clear all
fs = 2000; % sampling frequency
T = 20000;

% PAC signal 1
f1 = 20 / fs;
f2 = 250 / fs;
e1 = cos(2 * pi * f1 * (1:T) + 0.1 * cumsum(randn(1, T)));
e2 = exp(-2*e1) .* cos(2 * pi * f2 * (1:T)) / 4;
x = e1 + e2;
x1 = x(:);

% PAC signal 2
f1 = 10 / fs;
f2 = 200 / fs;
e1 = cos(2 * pi * f1 * (1:T) + 0.1 * cumsum(randn(1, T)));
e2 = exp(-2*e1) .* cos(2 * pi * f2 * (1:T)) / 4;
x = e1 + e2;
x2 = x(:);

% Put both into one SampledProcess
s = SampledProcess([x1 , x2],'Fs',fs);
c = CFC('input',s,'metric','mi');
c.run.plot;

% Try a different metric
c.metric = 'canolty';
c.run.plot;

c.filterBankType = 'eeglab_fir1'; % Hemptinne
c.metric = 'tort';
c.run.plot;

c.filterBankType = 'eeglab_firls'; % Ozkurt
c.metric = 'tort';
c.run.plot;
% examine filters
fvtool(c.hAmp)

c.filterBankType = 'uniform';
c.run.plot;

%%
clear all
fs = 1000;
dt = 1/fs;

A = 1;
M = 1;
fc = 140;
fm = 10;

% PAC signal
t = 0:dt:10;
x = sin(2*pi*fm*t) + (A + M*sin(2*pi*fm*t)).*sin(2*pi*fc*t);

% Create a uniform filterbank
[hp,ha] = sig.designFilterBankPAC(5:5:35,100:20:200,fs,'type','uniform','bwp',5,'bwa',20);
% Visualize resulting filters
fvtool(hp,'Fs',fs);
fvtool(ha,'Fs',fs);

% Place signal into SampledProcess
s = SampledProcess(x(:),'Fs',fs);

% Pass through the two filterbanks
sp = s.filterBank(hp);
sa = s.filterBank(ha);

% trim off edge artifacts
sp.window = [2 8];
sa.window = [2 8];

plot(sp);
plot(sa);
