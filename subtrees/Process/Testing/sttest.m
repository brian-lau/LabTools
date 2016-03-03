Fs = 1000;
dt = 1/Fs;
t = 0:dt:1;

x1 = exp(-35*pi*(t-0.5).^2).*cos(40*pi*t)...
   + exp(-35*pi*(t-0.5).^2).*cos(160*pi*t)...
   + exp(-55*pi*(t-0.2).^2).*cos(100*pi*t)...
   + exp(-55*pi*(t-0.8).^2).*cos(100*pi*t);

x2 = cos(20*pi*log(10*t+1)) + cos(48*pi*t+8*pi*t.^2);

x3 = cos(2*pi*100*t); x3(t>.5) = 0;
temp = cos(2*pi*400*t);
temp((t<=0.08)|(t>=.220)) = 0;
x3 = x3 + temp;
temp = cos(2*pi*200*t);
temp(t<=0.5) = 0;
x3 = x3 + temp;

figure;
subplot(2,3,1);
plot(t,x1);
subplot(2,3,4);
[S,f] = sig.fst(x1,'Fs',Fs,'fpass',[0 150]);
imagesc(t,f,abs(S)); set(gca,'ydir','normal');
subplot(2,3,2);
plot(t,x2);
subplot(2,3,5);
[S,f] = sig.fst(x2,'Fs',Fs,'fpass',[0 150]);
imagesc(t,f,abs(S)); set(gca,'ydir','normal');
subplot(2,3,3);
plot(t,x3);
subplot(2,3,6);
[S,f] = sig.fst(x3,'Fs',Fs,'fpass',[0 500]);
imagesc(t,f,abs(S)); set(gca,'ydir','normal');

x = x1 + .0*randn(size(x3));
st = @(params) sig.fst(x,'Fs',Fs,'fpass',[0 150],'params',params);
[X,FVAL,EXITFLAG,OUTPUT] = ...
   fminsearch(@(params) -cm(feval(st,params)),[1/numel(x) 4*var(x)],struct('Display','iter'));

options = optimoptions(@fmincon,'Algorithm','Active-set','Display','iter');
[X,FVAL,EXITFLAG,OUTPUT] = ...
   fmincon(@(params) -cm(feval(st,params)),[1/numel(x) 4*var(x)],...
   [],[],[],[],[0 0],[3 3],[],options);
[X,FVAL,EXITFLAG,OUTPUT] = ...
   fmincon(@(params) -cm(feval(st,params)),[0.1 0.1 0.1 0.1],...
   [],[],[],[],[0 0 0 0],[3 3 3 3],[],options);
[X,FVAL,EXITFLAG,OUTPUT] = ...
   fmincon(@(params) -cm(feval(st,params)),[1],...
   [],[],[],[],[0],[10],[],options);
% 
% X = ga(@(params) -cm(feval(st,params)),3,[],[],[],[],[0 0 0],[3 3 3])
%[X,FVAL] = simulannealbnd(@(params) -cm(feval(st,params)),[1/numel(x) 4*var(x)],[0 0],[1 1],struct('Display','iter'))
%[X,FVAL] = particleswarm(@(params) -cm(feval(st,params)),2,[0 0],[1 1])

figure;
subplot(1,2,1);
S = feval(st,1);
imagesc(t,f,abs(S)); set(gca,'ydir','normal');
subplot(1,2,2);
S = feval(st,X);
imagesc(t,f,abs(S)); set(gca,'ydir','normal');
