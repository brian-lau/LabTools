Fs = 1000;
T = 20;
s = fakeLFP2(Fs,T,2);

f = 0:.25:500;
nw = 4;

psdParams = struct('f',0:.25:500,'thbw',nw);
Sp = Spectrum('input',s,'psdParams',psdParams);
Sp.whitenParams.method = 'power';
Sp.run;
Sp.plotDiagnostics;
Sp.plot;

% Removed this method, not very accurate, lives in spectrum branch of LabTools
% Sa = Spectrum('input',s,'psdParams',psdParams);
% Sa.whitenParams.method = 'ar';
% Sa.run;
% Sa.plotDiagnostics;
% Sa.plot;

%%
s1 = fakeLFP2(Fs,T,1);
s2 = fakeLFP2(Fs,T,2);

s = SampledProcess([s1.values{1} s2.values{1}],'Fs',Fs);

psdParams = struct('f',0:.25:500,'thbw',nw);
Sp = Spectrum('input',s,'psdParams',psdParams);
Sp.whitenParams.method = 'power';
Sp.run;
Sp.plotDiagnostics;
Sp.plot;

% Removed this method, not very accurate, lives in spectrum branch of LabTools
% Sa = Spectrum('input',s,'psdParams',psdParams);
% Sa.whitenParams.method = 'ar';
% Sa.run;
% Sa.plotDiagnostics;
% Sa.plot;

