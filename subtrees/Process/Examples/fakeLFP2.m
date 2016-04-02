function [s,f,Sx0] = fakeLFP2(Fs,T,signal)
%rng(1111234);

if nargin < 3
   signal = false;
end

if nargin < 2
   T = 10;
end
if nargin < 1
   Fs = 2000;
end

%Fs = 2000;

A = 0.9;
sigma = 1;
f = 0:.5:(Fs/2);

% AR(1) process as background
x0 = arsim(0,A,sigma,T*Fs);
Sx0 = stat.arspectrum(A,sigma,Fs,f);
t = (1/Fs)*(0:numel(x0)-1)';
n = numel(t);

if signal == 1
   %% Some gaussian bumps in frequency
   ff = linspace(0,Fs/2,n/2 + 1);
   gp1 = normpdf(ff,12,2);
   gp1 = gp1./max(gp1);
   gp2 = normpdf(ff,22,4);
   gp2 = gp2./max(gp2);
   gp3 = normpdf(ff,80,5);
   gp3 = gp3./max(gp3);
   gp4 = normpdf(ff,250,20);
   gp4 = gp4./max(gp4);
   gp = gp1*1 + gp2*.75 + gp3*.25 + gp4*.25/4;
   x1 = sig.noise(gp);

   % Sum together, with a line component for good measure
   x = x0 + 1*cos(2*pi*4*t) + 15*x1;
elseif signal == 2 % 1/f background
   %% Some gaussian bumps in frequency
   ff = linspace(0,Fs/2,n/2 + 1);
   gp1 = normpdf(ff,12,2);
   gp1 = gp1./max(gp1);
   gp2 = normpdf(ff,22,4);
   gp2 = gp2./max(gp2);
   gp3 = normpdf(ff,80,5);
   gp3 = gp3./max(gp3);
   gp4 = normpdf(ff,250,20);
   gp4 = gp4./max(gp4);
   gp = gp1*1 + gp2*.75 + gp3*.25 + gp4*.25/2;
   x1 = sig.noise(gp);

   % Sum together, with a line component for good measure
   x = 1.5*cos(2*pi*4*t) + 15*x1 + 4*sig.pinknoise(numel(x1))';
else
   x = x0;
end

s = SampledProcess(x,'Fs',Fs);
