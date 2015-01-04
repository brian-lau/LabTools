function test_suite = testProcessTStart
initTestSuite;

function testNoArgs
% Not enough parameters to do any alignment
p =  PointProcess();
assertTrue(isa(p,'PointProcess'),'Constructor failed to create PointProcess without inputs');

function testPointProcessSingleArg
p = PointProcess(0);
assertEqual(p.tStart,0);

p = PointProcess(10);
assertEqual(p.tStart,0);

p = PointProcess(-10);
assertEqual(p.tStart,-10);

p = PointProcess(-1:10);
assertEqual(p.tStart,-1);

p = PointProcess(0);
assertEqual(p.tStart,0);

function testSampledProcessSingleArg
s = SampledProcess(0);
assertEqual(s.tStart,0);
assertEqual(s.times{1}(1),0);
assertEqual(s.times_(1),0);

s = SampledProcess(100);
assertEqual(s.tStart,0);
assertEqual(s.times{1}(1),0);
assertEqual(s.times_(1),0);

s = SampledProcess(-100);
assertEqual(s.tStart,0);
assertEqual(s.times{1}(1),0);
assertEqual(s.times_(1),0);

function testPointProcessContructTstart
p = PointProcess('times',0:10,'tStart',0);
assertEqual(p.tStart,0);

p = PointProcess('times',0:10,'tStart',10);
assertEqual(p.tStart,10);

p = PointProcess('times',0:10,'tStart',-10);
assertEqual(p.tStart,-10);

% Odd situation where tStart will empty times
% Don't have this issue with SampledProcess, since we can only specify tStart
p = PointProcess('times',0:10,'tStart',100);
assertEqual(p.tStart,100);

function testSampledProcessContructTstart
s = SampledProcess('values',1:10,'tStart',100);
assertEqual(s.tStart,100);
assertEqual(s.times{1}(1),100);
assertEqual(s.times_(1),100);

s = SampledProcess('values',1:10,'tStart',-100);
assertEqual(s.tStart,-100);
assertEqual(s.times{1}(1),-100);
assertEqual(s.times_(1),-100);

function testPointProcessSetTstart
p = PointProcess('times',0:10,'values',0:10);
p.tStart = 5;
assertEqual(p.tStart,5);
assertEqual(p.times_{1}',5:10);
assertEqual(numel(p.times_{1}),numel(p.values_{1}));
assertEqual(p.values_{1}',5:10);
assertEqual(p.times{1}',5:10);
assertEqual(numel(p.times{1}),numel(p.values{1}));
assertEqual(p.values{1}',5:10);

p = PointProcess('times',0:10,'values',0:10);
p.tStart = -5;
assertEqual(p.tStart,-5);
assertEqual(p.times_{1}',0:10);
assertEqual(numel(p.times_{1}),numel(p.values_{1}));
assertEqual(p.values_{1}',0:10);
assertEqual(p.times{1}',0:10);
assertEqual(numel(p.times{1}),numel(p.values{1}));
assertEqual(p.values{1}',0:10);

f = @() set(p,'tStart',11);
assertExceptionThrown(f, 'PointProcess:tStart:InputValue');

function testSampledProcessSetTstart
s = SampledProcess('values',0:10);
s.tStart = 5;
assertEqual(s.tStart,5);
assertEqual(s.times_',5:10);
assertEqual(numel(s.times_),numel(s.values_));
assertEqual(s.values_',5:10);
assertEqual(s.times{1}',5:10);
assertEqual(numel(s.times{1}),numel(s.values{1}));
assertEqual(s.values{1}',5:10);

s = SampledProcess('values',0:10);
s.tStart = -5;
assertEqual(s.tStart,-5);
assertEqual(s.times_',-5:10);
assertEqual(numel(s.times_),numel(s.values_));
assertEqual(s.values_',[nan(1,5),0:10]);
assertEqual(s.times{1}',-5:10);
assertEqual(numel(s.times{1}),numel(s.values{1}));
assertEqual(s.values{1}',[nan(1,5),0:10]);

f = @() set(s,'tStart',11);
assertExceptionThrown(f, 'SampledProcess:tStart:InputValue');
