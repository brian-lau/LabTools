%%
% Trial 1, 0:1 seconds
dt = 0.00001;
t = cos(2*pi*(0:dt:(1-dt)))';
s(1) = SampledProcess('values',t,'Fs',1/dt);

dt = 0.0001;
t = cos(2*pi*(0:dt:(1-dt))+pi/2)';
s(2) = SampledProcess('values',t,'Fs',1/dt);

info(1).tAlign = 1;
sig{1} = s;

% Trial 2, 0:3 seconds
dt = 0.00001;
t = cos(2*pi*(0:dt:(3-dt)))';
s(1) = SampledProcess('values',t,'Fs',1/dt);

dt = 0.0001;
t = cos(2*pi*(0:dt:(3-dt))+pi/2)';
s(2) = SampledProcess('values',t,'Fs',1/dt);

info(2).tAlign = 2;
sig{2} = s;

plot(sig{1})
plot(sig{2})

% Segment container
for i = 1:numel(sig)
   temp = containers.Map(fieldnames(info(i)),struct2cell(info(i)));
   data(i) = Segment('info',temp,'process',sig{i});
end

%
query = linq();
out = query.place(data)...
   .where(@(x) numel(x.info('tAlign'))==1)...
   .select(@(x) x.sync(x.info('tAlign'),'window',[-2 2]))...
   .select(@(x) extract(x,'SampledProcess')).toArray();

out.apply(@(x) nanstd(x))

%%

data(1) = Segment('SampledProcess',...
   {SampledProcess(randn(5,2)) SampledProcess(randn(5,2))},...
   'PointProcess',PointProcess(1:5));
data(2) = Segment('SampledProcess',...
   [SampledProcess(randn(10,2)) SampledProcess(randn(10,2))],...
   'PointProcess',...
   PointProcess(1:10));

proc = data.extract('pid3')
proc{1}{1}
proc{2}{1}

proc = data.extract('pointprocess','type')
proc{1}{1}
proc{2}{1}


%%
clear
% signals sampled at same Fs, different tStart
dt = 0.00001;
x = cos(2*pi*(0:dt:(1-dt)))';
s(1) = SampledProcess('values',x,'Fs',1/dt,'tStart',0);
x = cos(2*pi*(-1:dt:(1-dt))+pi/2)';
s(2) = SampledProcess('values',x,'Fs',1/dt,'tStart',-1);
x = cos(2*pi*(-2:dt:(1-dt))+pi)';
s(3) = SampledProcess('values',x,'Fs',1/dt,'tStart',-2);
plot(s);

S = Segment('process',mat2cell(s,1,[1 1 1]));

window = [-2 2];
offset = [0.5 .25 1];
sync(S,offset,'window',window);

sync(s,offset,'window',window);
plot(s);