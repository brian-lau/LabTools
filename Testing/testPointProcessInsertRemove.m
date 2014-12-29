function test_suite = testPointProcessInsertRemove
initTestSuite;


%%
function testInsert
% Inserting times
p = PointProcess('times',1:10);
p.insert([11:20],2*ones(10,1));
assertEqual(p.times_,{(1:20)'});
assertEqual(p.values_,{[ones(10,1) ; 2*ones(10,1)]});
% Window does not change
assertEqual(p.count,10);
assertEqual(p.times{1},(1:10)');
assertEqual(p.index{1},(1:10)');
% But start and end times do
assertEqual(p.tStart,0);
assertEqual(p.tEnd,20);
% But explicit window change reflects new times
p.window = [0 20];
assertEqual(p.count,20);
assertEqual(p.times{1},(1:20)');
assertEqual(p.index{1},(1:20)');

clear p;
p = PointProcess('times',1:10,'window',[0 20]);
assertFalse(p.isValidWindow);
p.insert([11:20],2*ones(10,1));
assertEqual(p.times_,{(1:20)'});
assertTrue(p.isValidWindow);
% Initialization of bigger window now includes times automatically
assertEqual(p.count,20);
assertEqual(p.times{1},(1:20)');
assertEqual(p.index{1},(1:20)');

clear p;
p = PointProcess('times',11:20,'window',[10 20],'tStart',11);
assertFalse(p.isValidWindow);
p.insert([1:10],2*ones(10,1));
% Original window doesn't fully cover the newly inserted times
assertEqual(p.times_,{(1:20)'});
assertEqual(p.values_,{[2*ones(10,1) ; ones(10,1)]});
assertEqual(p.times{1},(10:20)');
assertEqual(p.index{1},(10:20)');
assertEqual(p.tStart,1);
assertEqual(p.tEnd,20);
assertTrue(p.isValidWindow);

function testInsert_multi
% Inserting times
p = PointProcess('times',{1:5 6:10},'window',[0 5]);
p.insert([1:10],2*ones(10,1));
assertEqual(p.times_,{(1:10)' (1:10)'});
assertEqual(p.values_{1},[ones(5,1) ; 2*ones(5,1)]);
assertEqual(p.values_{2},[2*ones(5,1) ; ones(5,1)]);
% Window does not change
assertEqual(p.count,[5 5]);
assertEqual(p.times,{(1:5)' (1:5)'});
assertEqual(p.index,{(1:5)' (1:5)'});
% % But start and end times do
% assertEqual(p.tStart,0);
% assertEqual(p.tEnd,20);
% But explicit window change reflects new times
p.window = [0 10];
assertEqual(p.count,[10 10]);
assertEqual(p.times,{(1:10)' (1:10)'});
assertEqual(p.values,{[ones(5,1) ; 2*ones(5,1)] [2*ones(5,1) ; ones(5,1)]});
assertEqual(p.index,{(1:10)' (1:10)'});

clear p;
p = PointProcess('times',{1:5 6:10},'window',[0 20]);
assertFalse(p.isValidWindow);
p.insert([1:10],2*ones(10,1));
assertEqual(p.times_,{(1:10)' (1:10)'});
assertEqual(p.values_,{[ones(5,1) ; 2*ones(5,1)] [2*ones(5,1) ; ones(5,1)]});
assertFalse(p.isValidWindow);
% Initialization of bigger window now includes times automatically
assertEqual(p.count,[10 10]);
assertEqual(p.times,{(1:10)' (1:10)'});
assertEqual(p.index,{(1:10)' (1:10)'});


function testInsertWithValues
p = PointProcess(1:10);
%p.insert([0 11],{'test1' 'test2'});
p.insert([0 11],[2 3]);
assertEqual(p.tStart,0);
assertEqual(p.tEnd,11);
assertEqual(p.times_,{[0 1:10 11]'});
assertEqual(p.times{1},(1:10)');
assertEqual(p.values_,{[2 ones(1,10) 3]'});

% function testInsertWithMap
% p = PointProcess('times',[1:3],'window',[0 20]);
% p.insert(containers.Map({4},{'dog'}));
% assertEqual(p.times_,1:4);
% assertEqual(p.values_,{[] [] [] 'dog'});
% assertEqual(p.isValidWindow,false);
% assertEqual(p.count,4);
% 
% f = @() p.insert('dog');
% assertExceptionThrown(f,'PointProcess:insert:InputFormat')

% function testInsert2
% % multiple windows
% p = PointProcess('times',1:10,'window',[1 5; 6 10]);
% p.insert([1.5 6.5],{'test1' 'test2'});
% assertEqual(p.times_,[1 1.5 2:6 6.5 7:10]);
% assertEqual(p.values{1},{[] 'test1' [] [] [] []});
% assertEqual(p.values{2},{[] 'test2' [] [] [] []});
% 
% function testInsertWithOffset
% p = PointProcess('times',1:10,'window',[-10 10],'offset',5);
% p.insert([1.5 9.5]);
% assertEqual(p.times_,[1 1.5 2:9 9.5 10]);
% assertEqual(p.times{1},5+[1 1.5 2:9 9.5 10]);

function testRemove
p = PointProcess('times',1:10);
p.remove(6:10);
assertEqual(p.times_,{(1:5)'});
assertEqual(p.count,5);
assertEqual(p.values_,{ones(5,1)}');
assertEqual(p.times{1},(1:5)');
assertEqual(p.index{1},(1:5)');

% with existing non-zero offset
p = PointProcess('times',0:9,'offset',1);
p.remove(0:2:9);
assertEqual(p.times_,{[1:2:9]'});
assertEqual(p.count,5);
assertEqual(p.times{1},(1:2:9)' + p.offset);
assertEqual(p.index{1},(1:5)');

