function s = fakeLFP2(Fs,T,signal)
%function [s,f,Sx0] = fakeLFP2(Fs,T,signal)
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

t = (1/Fs)*(0:T*Fs-1)';
n = numel(t);
ff = linspace(0,Fs/2,n/2 + 1)';

switch signal
   case 0 % white
      x = randn(T*Fs,1);
   case 1 % pink
      x = sig.pinknoise(T*Fs)';
   case 2
      % Red noise background
      A = 0.9;
      sigma = 1;
      %f = 0:.5:(Fs/2);
      %Sx0 = stat.arspectrum(A,sigma,Fs,f);
      x = arsim(0,A,sigma,T*Fs); % AR(1) process
   case 3
      x = sig.pinknoise(T*Fs)';
      x = x + 1*cos(2*pi*4*t) + 1*cos(2*pi*10*t) + 1*cos(2*pi*30*t) + 1*cos(2*pi*90*t)...
          + 1*cos(2*pi*300*t);
   case 4
      bl = stat.baseline.smbrokenpl([100 2 .5 2 30],ff);
      bl(isinf(bl)) = 0;
      x = sig.noise(sqrt(bl));
   case 5 % 1/f background with some gaussian bumps in frequency
      f = [12 30 90 300];
      sd = [1 3 3 20];
      
      bl = 1./ff;
      for i = 1:numel(f)
         temp = normpdf(ff,f(i),sd(i));
         temp = temp./max(temp);
         gp(:,i) = temp/f(i);
      end
      gp = sum(gp,2) + .5*bl;
      gp(isinf(gp)) = 0;
      x = sig.noise(sqrt(gp));
   case 6 %% Some gaussian bumps in frequency
      f = [12 30 90 300];
      sd = [1 3 3 20];
      
      bl = stat.baseline.smbrokenpl([1 2 .5 2 30],ff);
      for i = 1:numel(f)
         temp = normpdf(ff,f(i),sd(i));
         temp = temp./max(temp);
         
         ind = ff==f(i);
         gp(:,i) = temp*bl(ind);
      end
      gp = 100*(sum(gp,2) + .5*bl);
      gp(isinf(gp)) = 0;
      x = sig.noise(sqrt(gp));
end

% A = 0.9;
% sigma = 1;
% f = 0:.5:(Fs/2);
% % AR(1) process as background
% x0 = arsim(0,A,sigma,T*Fs);
% Sx0 = stat.arspectrum(A,sigma,Fs,f);
% t = (1/Fs)*(0:numel(x0)-1)';
% n = numel(t);
% 
% if signal == 1
%    %% Some gaussian bumps in frequency
%    ff = linspace(0,Fs/2,n/2 + 1);
%    gp1 = normpdf(ff,12,2);
%    gp1 = gp1./max(gp1);
%    gp2 = normpdf(ff,22,4);
%    gp2 = gp2./max(gp2);
%    gp3 = normpdf(ff,80,5);
%    gp3 = gp3./max(gp3);
%    gp4 = normpdf(ff,250,20);
%    gp4 = gp4./max(gp4);
%    gp = gp1*1 + gp2*.75 + gp3*.25 + gp4*.25/4;
%    x1 = sig.noise(gp);
% 
%    % Sum together, with a line component for good measure
%    x = x0 + 1*cos(2*pi*4*t) + 15*x1;
% elseif signal == 2 % 1/f background
%    %% Some gaussian bumps in frequency
%    ff = linspace(0,Fs/2,n/2 + 1);
%    gp1 = normpdf(ff,12,2);
%    gp1 = gp1./max(gp1);
%    gp2 = normpdf(ff,22,4);
%    gp2 = gp2./max(gp2);
%    gp3 = normpdf(ff,80,5);
%    gp3 = gp3./max(gp3);
%    gp4 = normpdf(ff,250,20);
%    gp4 = gp4./max(gp4);
%    gp = gp1*1 + gp2*.75 + gp3*.25 + gp4*.25/2;
%    x1 = sig.noise(gp);
% 
%    % Sum together, with a line component for good measure
%    x = 1.5*cos(2*pi*4*t) + 15*x1 + 4*sig.pinknoise(numel(x1))';
% elseif signal == 3
%    keyboard
% else
%    x = x0;
% end

s = SampledProcess(x,'Fs',Fs);
