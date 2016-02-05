s = SampledProcess(randn(10000,1),'Fs',1000);
lowpass(s,'Fpass',100,'Fstop',150); 
h = tfr(s,'tBlock',s.tEnd,'tStep',s.tEnd + 1,'f',0:500);
plot(h);

reset(s);
highpass(s,'Fpass',50,'Fstop',2); 
h = tfr(s,'tBlock',s.tEnd,'tStep',s.tEnd + 1,'f',0:500);
plot(h);

reset(s);
bandpass(s,'Fstop1',1,'Fpass1',100,'Fpass2',250,'Fstop2',260,'plot',true,'verbose',true); 
h = tfr(s,'tBlock',s.tEnd,'tStep',s.tEnd + 1,'f',0:500);
plot(h);

reset(s);
bandpass(s,'Fstop1',1,'Fpass1',100,'Fpass2',250,'Fstop2',260,'attenuation1',20,'attenuation2',60,'ripple',1,'plot',true,'verbose',true); 
h = tfr(s,'tBlock',s.tEnd,'tStep',s.tEnd + 1,'f',0:500);
plot(h);

reset(s);
bandstop(s,'Fstop1',48,'Fpass1',46,'Fpass2',52,'Fstop2',50,'plot',true,'verbose',true); 
h = tfr(s,'tBlock',s.tEnd,'tStep',s.tEnd + 1,'f',0:500);
plot(h,'log',false);

