function test_suite = testPointProcessConstructor
initTestSuite;


function testNoArgs
% Not enough parameters to do any alignment
p =  PointProcess();
assertTrue(isa(p,'PointProcess'),'Constructor failed to create PointProcess without inputs');

function testSingleArg
p = PointProcess(1:10);
assertEqual(p.times_,{(1:10)'});
assertEqual(p.values_,{ones(10,1)});
assertEqual(p.tStart,0);
assertEqual(p.tEnd,10);
assertEqual(p.times,{(1:10)'});
assertEqual(p.index,{(1:10)'});
assertTrue(p.isValidWindow);
assertEqual(p.values,{ones(10,1)});
assertEqual(p.count,10);
assertEqual(p.window_,[1 10]);
assertEqual(p.offset_,0);

f = @() PointProcess('shouldnotwork');
assertExceptionThrown(f, 'PointProcess:Constructor:InputFormat');

f = @() PointProcess({'shouldnotwork'});
assertExceptionThrown(f, 'PointProcess:Constructor:InputFormat');

function testNoTimes
p = PointProcess('info',containers.Map({'cat'},{'dog'}));
assertEqual(p.count,0);
assertEqual(p.times_,[]);
assertEqual(p.times,[]);
assertEqual(p.values_,[]);
assertEqual(p.values,[]);

%%
function testTimes
% Creating object with times alone
p = PointProcess('times',1:10);
assertEqual(p.times_,{(1:10)'});
assertEqual(p.values_,{ones(10,1)});
assertEqual(p.tStart,0);
assertEqual(p.tEnd,10);
assertEqual(p.times,{(1:10)'});
assertEqual(p.values,{ones(10,1)});
assertEqual(p.index,{(1:10)'});
assertTrue(p.isValidWindow);
assertEqual(p.count,10);

function testTimesWindow1
% Creating object with times and window
p = PointProcess('times',1:10,'window',[5 10]);
assertEqual(p.window,[5 10]);
assertEqual(p.count,6);
assertEqual(p.times,{(5:10)'});
assertEqual(p.index,{(5:10)'});
assertEqual(p.isValidWindow,true);

function testTimesWindow2
% Creating object with times and window
p = PointProcess('times',1:10,'window',[-5 5]);
assertEqual(p.window,[-5 5]);
assertEqual(p.count,5);
assertEqual(p.times,{(1:5)'});
assertEqual(p.index,{(1:5)'});
assertFalse(p.isValidWindow);

function testTimesWindow3
% Creating object with times and multiple window
p = PointProcess('times',1:10,'window',[1 5 ; 6 11]);
assertEqual(p.window,[1 5 ; 6 11]);
assertEqual(p.count,[5 5]');
assertEqual(p.times,{(1:5)' ; (6:10)'});
assertEqual(p.values,{ones(5,1) ; ones(5,1)});
assertEqual(p.index,{(1:5)' ; (6:10)'});
assertEqual(p.isValidWindow,[true false]');

function testTimestStart
p = PointProcess('times',1:10,'tStart',5);
assertEqual(p.times_,{(5:10)'});
assertEqual(p.times,{(5:10)'});
assertEqual(p.values,{ones(6,1)});
assertEqual(p.window,[5 10]);
assertEqual(p.tStart,5);
assertEqual(p.tEnd,10);
assertEqual(p.window_,[5 10]);
assertEqual(p.offset_,0);

function testTimestEnd
p = PointProcess('times',1:10,'tEnd',5);
assertEqual(p.times_,{(1:5)'});
assertEqual(p.times,{(1:5)'});
assertEqual(p.values,{ones(5,1)});
assertEqual(p.window,[1 5]);
assertEqual(p.tStart,0);
assertEqual(p.tEnd,5);
assertEqual(p.window_,[1 5]);
assertEqual(p.offset_,0);

function testTimesOffset
p = PointProcess('times',1:10,'offset',5);
assertEqual(p.times_,{(1:10)'});
assertEqual(p.times,{(1:10)'+5});
assertEqual(p.window,[1 10]);
assertEqual(p.tStart,0);
assertEqual(p.tEnd,10);
assertEqual(p.window_,[1 10]);
assertEqual(p.offset_,5);

function testTimesValues
p = PointProcess('times',1:10,'values',1:10);
assertEqual(p.times_,{(1:10)'});
assertEqual(p.times,{(1:10)'});
assertEqual(p.values,{(1:10)'});

function testTimesValues2
p = PointProcess('times',1:10,'values','abcdefghij');
assertEqual(p.times_,{(1:10)'});
assertEqual(p.times,{(1:10)'});
assertEqual(p.values,{['abcdefghij']'});

function testTimesValues3
z(10) = PointProcess;
p = PointProcess('times',1:10,'values',z);
assertEqual(p.times_,{(1:10)'});
assertEqual(p.times,{(1:10)'});
assertEqual(p.values_,{z'});
assertEqual(p.values,{z'});

function testInfo
keys = {'cat' 'shine' 'rain'};
values = {'dog' 'monkey' 1:10};
p = PointProcess('info',containers.Map(keys,values));
map = containers.Map(keys,values);
assertEqual(p.info.keys,map.keys);
assertEqual(p.info.values,map.values);

