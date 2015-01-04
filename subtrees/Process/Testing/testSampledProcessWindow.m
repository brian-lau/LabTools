%%%%%%%%%%%% Windows outside of process start and end times extend as NaNs
s = SampledProcess('values',1:5,'Fs',1,'tStart',0);
assertEqual(s.times{1},(0:4)');
assertEqual(s.values{1},(1:5)');

s.window = [-1.5 2];
assertEqual(s.times{1},(-1:2)');
assertEqual(s.values{1},[NaN;(1:3)']);

s.window = [0 5.9];
assertEqual(s.times{1},(0:5)');
assertEqual(s.values{1},[(1:5)';NaN]);

s.window = [-1.5 5.5];
assertEqual(s.times{1},(-1:5)');
assertEqual(s.values{1},[NaN;(1:5)';NaN]);

s.window = [-1.5 2 ; 0 5.9];
assertEqual(s.times{1},(-1:2)');
assertEqual(s.times{2},(0:5)');
assertEqual(s.values{1},[NaN;(1:3)']);
assertEqual(s.values{2},[(1:5)';NaN]);

%% 
Fs = 1000;
dt = 1/Fs;
s = SampledProcess('values',1:5,'Fs',Fs,'tStart',0);
assertEqual(s.times{1},(0:4)'./Fs);
assertEqual(s.values{1},(1:5)');

s.window = [-1.5 2]./Fs;
assertEqual(s.times{1},(-1:2)'./Fs);
assertEqual(s.values{1},[NaN;(1:3)']);

s.window = [0 5.9]./Fs;
assertEqual(s.times{1},(0:5)'./Fs);
assertEqual(s.values{1},[(1:5)';NaN]);

s.window = [-1.5 5.5]./Fs;
assertEqual(s.times{1},(-1:5)'./Fs);
assertEqual(s.values{1},[NaN;(1:5)';NaN]);

s.window = [-1.5 2 ; 0 5.9]./Fs;
assertEqual(s.times{1},(-1:2)'./Fs);
assertEqual(s.times{2},(0:5)'./Fs);
assertEqual(s.values{1},[NaN;(1:3)']);
assertEqual(s.values{2},[(1:5)';NaN]);



