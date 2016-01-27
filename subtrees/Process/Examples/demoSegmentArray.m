%%
clear all;
ntrials = 10;

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
   y = [y,0.85*y,0.65*y];
   
   % Simulate PointProcess
   sp = 2+t1(i) + (0:.1:1);
   if rem(i,2)
      sp = [sp , 5+t1(i)+t2(i) + (0:.1:1)];
   end
   sp = {sp sp+.01 sp+.02 sp+.03 sp+.04 sp+.05};
   
   lfp = SampledProcess('values',y,'Fs',1/dt,'tStart',0,'tEnd',10);
   tf_lfp = tfr(lfp,'f',0:500,'tBlock',.5,'tStep',.2);
   emg = SampledProcess('values',-y,'Fs',1/dt,'tStart',0,'tEnd',10);
   tf_emg = tfr(emg,'f',0:500,'tBlock',.5,'tStep',.2);
   spikes = PointProcess('times',sp,'tStart',0,'tEnd',10);
   events = EventProcess('events',e,'tStart',0,'tEnd',10);
   
   % Pack everything into Segment container
   if rand > .5
      data(i) = Segment('process',{lfp tf_lfp events},'labels',{'lfp' 'tf_lfp' 'events'});
   else
      data(i) = Segment('process',{lfp tf_lfp emg spikes events},'labels',{'lfp' 'tf_lfp' 'emg' 'spikes' 'events'});
   end
   data(i).info('trial') = trial;
   clear e;
end
