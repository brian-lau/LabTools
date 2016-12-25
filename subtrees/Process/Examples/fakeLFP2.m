function s = fakeLFP2(Fs,T,signal)
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
      %bl = stat.baseline.smbrokenpl([100 2 .5 2 30],ff);
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
   case 7 %% Some gaussian bumps in frequency
      f = [12 30 90 300];
      sd = [1 3 3 20];
      
      bl = stat.baseline.smbrokenpl([1 -5 3 1 30],ff);
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

s = SampledProcess(x,'Fs',Fs);
