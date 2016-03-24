dt = 1;
t = 0:dt:127;

x = zeros(size(t));
ind = (t>=0)&(t<=20);
x(ind) = cos(2*pi*0.1*t(ind));
ind = (t>20)&(t<32);
x(ind) = cos(2*pi*0.1*t(ind)) + cos(2*pi*0.4*t(ind));
ind = (t>=32)&(t<=36);
x(ind) = cos(2*pi*0.1*t(ind));
ind = (t>36)&(t<48);
x(ind) = cos(2*pi*0.1*t(ind)) + cos(2*pi*0.4*t(ind));
ind = (t>=48)&(t<64);
x(ind) = cos(2*pi*0.1*t(ind));
ind = (t>=64)&(t<=127);
x(ind) = cos(2*pi*0.2*t(ind));

timeseries = x';
n = length(x);
ts_spe = fft(real(timeseries));
h = [1; 2*ones(fix((n-1)/2),1); ones(1-rem(n,2),1); zeros(fix((n-1)/2),1)];
ts_spe(:) = ts_spe.*h(:);
timeseries = ifft(ts_spe);
y = timeseries';

[S,f,t] = sig.fst(hilbert(x),'Fs',1/dt);
imagesc(t,f,angle(S)); set(gca,'ydir','normal');

[S,f,t] = sig.fst(y,'Fs',1/dt);
imagesc(t,f,angle(S)); set(gca,'ydir','normal');


fs = 256;
dt = 1/fs;
t = -2:dt:2;

x = zeros(size(t));
ind = (t>=-2)&(t<=0);
x(ind) = exp(-1j*10*pi*log(-25*t(ind)+1));
ind = (t>0)&(t<=2);
x(ind) = exp(1j*10*pi*log(25*t(ind)+1));

[S,f,t] = sig.fst(x,'Fs',1/dt);
imagesc(t,f,angle(S)); set(gca,'ydir','normal');



fs = 256;
dt = 1/fs;
t = -2:dt:2;

x = zeros(size(t));
ind = (t>=-2)&(t<=2);
x(ind) = cos(2*pi*60*t(ind));

timeseries = x';
n = length(x);
ts_spe = fft(real(timeseries));
h = [1; 2*ones(fix((n-1)/2),1); ones(1-rem(n,2),1); zeros(fix((n-1)/2),1)];
ts_spe(:) = ts_spe.*h(:);
timeseries = ifft(ts_spe);
y = timeseries';

[S,f,t] = sig.fst(x,'Fs',1/dt);
imagesc(t,f,abs(S)); set(gca,'ydir','normal');

imagesc(t,f,angle(S)); set(gca,'ydir','normal');
