Fs = 1000;
T = 20;
s1 = fakeLFP2(Fs,T,1);
s2 = fakeLFP2(Fs,T,2);

s = SampledProcess([s1.values{1} s2.values{1}],'Fs',Fs);

f = 0:.5:500;
nw = 4;

psdParams = struct('f',f,'thbw',nw);
S = Spectrum('input',s,'psdParams',psdParams);
S.whitenParams.method = 'power';
S.run;

S.plotDiagnostics
%S.plot