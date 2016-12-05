% Basic categories of artifacts from:
% Islam et al 2014. J Neurosci Methods
function [s,artifacts,f,Sx] = fakeLFP(Fs,T,n)
rng(1111234);

if nargin < 3
   n = [3 3 3 3];
end
if nargin < 2
   T = 20;
end
if nargin < 1
   Fs = 2000;
end

% AR(6)
sigma = 1;
A = [3.9515 -7.8885 9.7340 -7.7435 3.8078 -0.9472];
x = arsim(0,A,sigma,T*Fs);
t = (1/Fs)*(0:numel(x)-1)';

% True (uncontaminated) spectrum
f = 0:.5:Fs/2;
den = zeros(size(f));
for i = 1:numel(A)
   den = den + A(i)*exp(-1j*2*pi*i*f/Fs);
end
den = abs(1-den).^2;
Sx = sigma^2/Fs./den;

%xf = sig.f_alpha_gaussian(T*Fs,1,1.5);
%x = x + xf;

xclean = x;

c = fig.distinguishable_colors(4);
count = 0;
% Type 0
params = [n(1) .5 100];
t0 = rand(params(1),1)*(T-params(2));
for i = 1:params(1)
   ind = (t>=t0(i))&(t<=(t0(i)+params(2)));
   tl = t(ind);
   tl = tl - tl(1);
   y = betapdf(tl,4,40);
   y = y./max(y);
   x(ind) = x(ind) + params(3)*y;
   
   count = count + 1;
   e(count) = metadata.event.Artifact('tStart',t0(i),'tEnd',t0(i)+params(2),...
      'name',metadata.Label('name','type0','color',c(1,:)));
end

% Type 1
params = [n(2) 1 100 8];
t0 = rand(params(1),1)*(T-params(2));
for i = 1:params(1)
   ind = (t>=t0(i))&(t<=(t0(i)+params(2)));
   si = (2*(rand>0.5)-1);
   tl = t(ind);
   tl = tl - tl(1);
   x(ind) = x(ind) + si*params(3)*exp(-params(4)*tl);

   count = count + 1;
   e(count) = metadata.event.Artifact('tStart',t0(i),'tEnd',t0(i)+params(2),...
      'name',metadata.Label('name','type1','color',c(2,:)));
end

% Type 2
params = [n(3) .2 100 -200];
t0 = rand(params(1),1)*(T-params(2));
for i = 1:params(1)
   ind = (t>=t0(i))&(t<=(t0(i)+params(2)));
   si = (2*(rand>0.5)-1);
   tl = t(ind);
   tl = tl - tl(1);
   x(ind) = x(ind) + si*params(3) + si*params(4)*tl;

   count = count + 1;
   e(count) = metadata.event.Artifact('tStart',t0(i),'tEnd',t0(i)+params(2),...
      'name',metadata.Label('name','type2','color',c(3,:)));
end

% Type 3
params = [n(4) .002 200];
t0 = rand(params(1),1)*(T-params(2));
for i = 1:params(1)
   ind = (t>=t0(i))&(t<=(t0(i)+params(2)));
   x(ind) = (2*(rand>0.5)-1)*params(3);

   count = count + 1;
   e(count) = metadata.event.Artifact('tStart',t0(i),'tEnd',t0(i)+params(2),...
      'name',metadata.Label('name','type3','color',c(4,:)));
end

s = SampledProcess([xclean,x],'Fs',Fs,'labels',{'clean' 'dirty'});
artifacts = EventProcess('events',e,'tStart',s.tStart,'tEnd',s.tEnd);
