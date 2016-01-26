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

%%
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

s.reset();
events(1) = metadata.Event('tStart',0.5);
events(2) = metadata.Event('tStart',0.25);
events(3) = metadata.Event('tStart',1);
sync(s,events,'window',window);
plot(s);


%%
clear all;
e(1) = metadata.event.Stimulus('tStart',0.5,'tEnd',1,'name','fix');
e(2) = metadata.event.Response('tStart',5,'tEnd',6,'name','button');
e(3) = metadata.event.Stimulus('tStart',1.5,'tEnd',3,'name','cue');

S = Segment('process',{PointProcess([1 4 4.5 5 5.5 6 10]) ...
             SampledProcess([0 0 0 0 0 1 0 0 0 0 0]) ...
             EventProcess('events',e)},'labels',{'point' 'sampled' 'event'});

e(1) = metadata.event.Stimulus('tStart',0.5,'tEnd',1,'name','fix');
e(2) = metadata.event.Response('tStart',5,'tEnd',6,'name','button');
e(3) = metadata.event.Stimulus('tStart',1,'tEnd',3,'name','cue');
          
S(2) = Segment('process',{PointProcess([1 4 4.5 5 5.5 6 10]) ...
             SampledProcess([0 0 0 0 0 1 0 0 0 0 0]) ...
             EventProcess('events',e)},'labels',{'point' 'sampled' 'event'});

e(1) = metadata.event.Stimulus('tStart',0.5,'tEnd',1,'name','fix');
e(2) = metadata.event.Response('tStart',5,'tEnd',6,'name','button');
e(3) = metadata.event.Stimulus('tStart',1,'tEnd',3,'name','cue2');
        
S(3) = Segment('process',{PointProcess([1 4 4.5 5 5.5 6 10]) ...
             SampledProcess([0 0 0 0 0 1 0 0 0 0 0]) ...
             EventProcess('events',e)},'labels',{'point' 'sampled' 'event'});

S.sync('name','cue','window',[-1 5])

%%
clear all;
ntrials = 30;

dt = 0.001;
t = (0:dt:(10-dt))';
for i = 1:ntrials  
   t1(i) = rand;
   t2(i) = rand;
   
   % Time-sensitive events
   e(1) = metadata.event.Stimulus('tStart',0.5,'tEnd',1,'name','fix');
   e(2) = metadata.event.Stimulus('tStart',2+t1(i),'tEnd',3+t1(i),'name','cue');
   if rem(i,2)
      e(3) = metadata.event.Response('tStart',5+t1(i)+t2(i),'tEnd',6+t1(i)+t2(i),'name','button');
   end

   % Test Trial data
   trial = metadata.trial.Msup;
   if rem(i,2)
      trial.isCorrect = true;
   else
      trial.isCorrect = false;
   end
   if rand<.5
      trial.isRepeat = true;
   else
      trial.isRepeat = false;
   end
   
   % Simulate SampledProcess
   y = normpdf(t,2+t1(i),.25);
   if rem(i,2)
      y = y - normpdf(t,5+t1(i)+t2(i),.5);
   end
   y = [y,0.85*y,0.65*y,0.55*y,0.35*y,0.15*y];
   
   % Simulate PointProcess
   sp = 2+t1(i) + (0:.1:1);
   if rem(i,2)
      sp = [sp , 5+t1(i)+t2(i) + (0:.1:1)];
   end
   sp = {sp sp+.01 sp+.02 sp+.03 sp+.04 sp+.05};
   
   % Pack everything into Segment container
   if rand > .5
      data(i) = Segment('process',...
         {...
         SampledProcess('values',y,'Fs',1/dt,'tStart',0,'tEnd',10) ...
         SampledProcess('values',-y,'Fs',1/dt,'tStart',0,'tEnd',10) ...
         PointProcess('times',sp,'tStart',0,'tEnd',10) ...
         EventProcess('events',e,'tStart',0,'tEnd',10) ...
         },...
         'labels',{'lfp' 'emg' 'spikes' 'events'});
   else
      data(i) = Segment('process',...
         {...
         SampledProcess('values',y,'Fs',1/dt,'tStart',0,'tEnd',10) ...
         tfr(SampledProcess('values',y,'Fs',1/dt,'tStart',0,'tEnd',10),'f',0:500,'tBlock',.5,'tStep',.2)...
         EventProcess('events',e,'tStart',0,'tEnd',10) ...
         },...
         'labels',{'lfp' 'tf' 'events'});
   end
   data(i).info('trial') = trial;
   clear e;
end


tic;data.sync('name','cue','window',[-4 5]);toc
data.reset
data.sync('name','button','window',[-5 2])
temp = linq(data).select(@(x) x.extract('lfp'))...
   .select(@(x) x.extract()).toArray;
a = cat(2,temp.values);
plot(temp(1).times,a)

temp = linq(data).select(@(x) x.extract('spikes'))...
   .select(@(x) x.extract()).toArray;
temp = cat(1,temp.times);
spk.plotRaster(temp);

temp = cell.flatten(data.extract('events'));
events = cat(1,temp{:});
% temp = cell.flatten(data.extract('lfp'));
% lfp = cat(1,temp{:});
% 
q = linq();
tCue = q(events)...
   .select(@(x) x.find('name','cue').tStart).toArray;
% tTargetOn = q(events)...
%    .select(@(x) x.find('name','target').tStart).toArray;
% tCueOn = q(events)...
%    .select(@(x) x.find('name','cue').tStart).toArray;
