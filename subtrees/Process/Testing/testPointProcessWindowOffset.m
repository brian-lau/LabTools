function test_suite = testPointProcessWindowOffset
initTestSuite;

%%
function testWindow
% Setting window alone
p = PointProcess('times',1:10);
p.window = [5 10];
assertEqual(p.window,[5 10]);
assertEqual(p.times_,{(1:10)'});
assertEqual(p.count,6);
assertEqual(p.times{1},(5:10)');
assertEqual(p.index{1},(5:10)');

function testWindow_multi
% Setting window alone, multiple processes (defined as having same start and end times)
% non-overlapping
p = PointProcess('times',{[1:5] [6:10]});
p.window = [5 10];
assertEqual(p.window,[5 10]);
assertEqual(p.times_,{(1:5)' (6:10)'});
assertEqual(p.count,[1 5]);
assertEqual(p.times,{5 (6:10)'});
assertEqual(p.index,{5 (1:5)'});
assertTrue(p.isValidWindow);

% overlapping
p = PointProcess('times',{[1:10] [6:10]});
p.window = [5 10];
assertEqual(p.window,[5 10]);
assertEqual(p.times_,{(1:10)' (6:10)'});
assertEqual(p.count,[6 5]);
assertEqual(p.times,{(5:10)' (6:10)'});
assertEqual(p.index,{(5:10)' (1:5)'});
assertTrue(p.isValidWindow);

% invalid window
p = PointProcess('times',{[1:10] [6:10]});
p.window = [-10 5];
assertEqual(p.window,[-10 5]);
assertEqual(p.times_,{(1:10)' (6:10)'});
assertEqual(p.count,[5 0]);
empty = 1;
empty(1) = [];
assertEqual(p.times,{(1:5)' empty'});
assertEqual(p.index,{(1:5)' empty'});
assertFalse(p.isValidWindow);

function testWindow2
% Setting window, then resetting 
p = PointProcess('times',1:10);
p.window = [1 5;5 10];
assertEqual(p.window,[1 5 ;5 10]);
assertEqual(p.times_,{(1:10)'});
assertEqual(p.count,[5;6]);
assertEqual(p.times{1},(1:5)');
assertEqual(p.times{2},(5:10)');
assertEqual(p.index{1},(1:5)');
assertEqual(p.index{2},(5:10)');

% Set window to inclusive (which was original)
p.setInclusiveWindow;
assertEqual(p.window,[1 10]);
assertEqual(p.times_,{(1:10)'});
assertEqual(p.count,10);
assertEqual(p.times{1},(1:10)');
assertEqual(p.index{1},(1:10)');
% Assign an offset
p.offset = 1;
assertEqual(p.window,[1 10]);
assertEqual(p.times_,{(1:10)'});
assertEqual(p.count,10);
assertEqual(p.offset,1);
assertEqual(p.times{1},(1:10)' + 1);
assertEqual(p.index{1},(1:10)');
% Set again to inclusive (should NOT zero offset)
% This doesn't zero offset since the window did not actually change
% Indeed, nothing will have changed (note AbortSet in property listener)
p.setInclusiveWindow;
assertEqual(p.window,[1 10]);
assertEqual(p.offset,1);
assertEqual(p.times_,{(1:10)'});
assertEqual(p.count,10);
assertEqual(p.times{1},(1:10)' + 1);
assertEqual(p.index{1},(1:10)');
% Try the above again with another window change
p.window = [0 12];
assertEqual(p.window,[0 12]);
assertEqual(p.offset,0);
assertEqual(p.times_,{(1:10)'});
assertEqual(p.count,10);
assertEqual(p.times{1},(1:10)');
assertEqual(p.index{1},(1:10)');
assertFalse(p.isValidWindow);

function testWindow2_multi
% Setting window, then resetting 
p = PointProcess('times',{[1:10] [6:10]});
p.window = [1 5;5 10];
assertEqual(p.window,[1 5 ;5 10]);
assertEqual(p.times_,{(1:10)' (6:10)'});
assertEqual(p.count,[5 0;6 5]);
empty = 1;
empty(1) = [];
assertEqual(p.times,{(1:5)' empty';(5:10)' (6:10)'});
assertEqual(p.index,{(1:5)' empty';(5:10)' (1:5)'});

% Set window to inclusive (which was original)
p.setInclusiveWindow;
assertEqual(p.window,[1 10]);
assertEqual(p.times_,{(1:10)' (6:10)'});
assertEqual(p.count,[10 5]);
assertEqual(p.times,{(1:10)' (6:10)'});
assertEqual(p.index,{(1:10)' (1:5)'});
assertTrue(p.isValidWindow);
% Assign an offset
p.offset = 1;
assertEqual(p.window,[1 10]);
assertEqual(p.times_,{(1:10)' (6:10)'});
assertEqual(p.count,[10 5]);
assertEqual(p.offset,1);
assertEqual(p.times,{(1:10)'+1 (6:10)'+1});
assertEqual(p.index,{(1:10)' (1:5)'});
% Set again to inclusive (should NOT zero offset)
% This doesn't zero offset since the window did not actually change
% Indeed, nothing will have changed (note AbortSet in property listener)
p.setInclusiveWindow;
assertEqual(p.window,[1 10]);
assertEqual(p.offset,1);
assertEqual(p.times_,{(1:10)' (6:10)'});
assertEqual(p.count,[10 5]);
assertEqual(p.offset,1);
assertEqual(p.times,{(1:10)'+1 (6:10)'+1});
assertEqual(p.index,{(1:10)' (1:5)'});
% Try the above again with another window change
p.window = [0 12];
assertEqual(p.window,[0 12]);
assertEqual(p.offset,0);
assertEqual(p.times_,{(1:10)' (6:10)'});
assertEqual(p.count,[10 5]);
assertEqual(p.offset,0);
assertEqual(p.times,{(1:10)' (6:10)'});
assertEqual(p.index,{(1:10)' (1:5)'});
assertFalse(p.isValidWindow);

function testWindow3
% Setting multiple windows 
p = PointProcess('times',0:10);
window = [(0:9)',(1:10)'];
p.window = window;
assertEqual(p.window,window);
assertEqual(p.times_,{(0:10)'});
assertEqual(p.count,repmat(2,10,1));
for i = 1:size(window,1)
   assertEqual(p.times{i},window(i,:)');
   assertEqual(p.index{i},window(i,:)' + 1);
end
% Offset different for each window
p.offset = -window(:,1);
for i = 1:size(window,1)
   assertEqual(p.times{i},[0 1]');
   assertEqual(p.index{i},window(i,:)' + 1);
   assertEqual(p.isValidWindow(i),true);
end
% Set inclusive window and check everything
p.setInclusiveWindow;
assertEqual(p.window,[0 10]);
assertEqual(p.offset,0);
assertEqual(p.times_,{(0:10)'});
assertEqual(p.count,11);
assertEqual(p.times{:},(0:10)');
assertEqual(p.index{:},(1:11)');

function testWindow3_multi
% Setting multiple windows 
p = PointProcess('times',{[0:10] [0:10]+.5});
window = [(0:9)',(1:10)'];
p.window = window;
assertEqual(p.window,window);
assertEqual(p.times_,{(0:10)' (0:10)'+.5});
assertEqual(p.count,[repmat(2,10,1) ones(10,1)]);
for i = 1:size(window,1)
   assertEqual(p.times(i,:),{window(i,:)' window(i,1)+.5});
   assertEqual(p.index(i,:),{window(i,:)'+1 i});
end
% Offset different for each window
p.offset = -window(:,1);
for i = 1:size(window,1)
   assertEqual(p.times(i,:),{[0 1]' 0.5});
   assertEqual(p.index(i,:),{window(i,:)'+1 i});
   assertEqual(p.isValidWindow(i),true);
end
% Set inclusive window and check everything
p.setInclusiveWindow;
assertEqual(p.window,[0 10.5]);
assertEqual(p.offset,0);
assertEqual(p.times_,{(0:10)' (0:10)'+.5});
assertEqual(p.count,[11 11]);
assertEqual(p.times,{(0:10)' (0:10)'+.5});
assertEqual(p.index,{(1:11)' (1:11)'});

function testSetWindow
p = PointProcess(1:10);
p.setWindow([1 5]);
assertEqual(p.window,[1 5]);
assertEqual(p.times{1},(1:5)');

p.setWindow([1 5;6 10]);
assertEqual(p.window,[1 5;6 10]);
assertEqual(p.times{1},(1:5)');
assertEqual(p.times{2},(6:10)');

f = @() p.setWindow('dog');
assertExceptionThrown(f,'Process:setWindow:InputFormat')

function testSetWindow_multi
p = PointProcess({[1:10] [1:10]-.5});
p.setWindow([1 5]);
assertEqual(p.window,[1 5]);
assertEqual(p.times,{(1:5)' (1:4)'+.5});

p.setWindow([1 5;6 10]);
assertEqual(p.window,[1 5;6 10]);
assertEqual(p.times,{(1:5)' (1:4)'+.5; (6:10)' (6:9)'+.5});

function testSetWindowWithObjectArray
p = PointProcess(1:10);
p.setWindow([1 5 ; 6 10]);
p.chop;

% same window for all
p.setWindow([0 4]);
assertEqual(p(1).window,[0 4]);
assertEqual(p(2).window,[0 4]);
assertEqual(p(1).times{1},(0:4)');
assertEqual(p(2).times{1},(0:4)');

p.setWindow([0 2 ; 3 4]);
assertEqual(p(1).window,[0 2 ; 3 4]);
assertEqual(p(2).window,[0 2 ; 3 4]);
assertEqual(p(1).times{1},(0:2)');
assertEqual(p(1).times{2},(3:4)');
assertEqual(p(2).times{1},(0:2)');
assertEqual(p(2).times{2},(3:4)');

f = @() p.setWindow('dog');
assertExceptionThrown(f,'Process:setWindow:InputFormat')

% different windows
p.setWindow({[0 2 ; 3 4] [0 4]});

assertEqual(p(1).window,[0 2 ; 3 4]);
assertEqual(p(1).times{1},(0:2)');
assertEqual(p(1).times{2},(3:4)');
assertEqual(p(2).window,[0 4]);
assertEqual(p(2).times{1},(0:4)');

function testSetWindowWithObjectArray_multi
p = PointProcess({1:10 [1:10]-.5});
p.setWindow([1 5 ; 6 10]);
p.chop;

% same window for all
p.setWindow([0 4]);
assertEqual(p(1).window,[0 4]);
assertEqual(p(2).window,[0 4]);
assertEqual(p(1).times,{(0:4)' (0:3)'+.5});
assertEqual(p(2).times,{(0:4)' (0:3)'+.5});

p.setWindow([0 2 ; 3 4]);
assertEqual(p(1).window,[0 2 ; 3 4]);
assertEqual(p(2).window,[0 2 ; 3 4]);
assertEqual(p(1).times,{(0:2)' (0:1)'+.5 ; (3:4)' 3.5});
assertEqual(p(2).times,{(0:2)' (0:1)'+.5 ; (3:4)' 3.5});

% different windows
p.setWindow({[0 2 ; 3 4] [0 4]});

assertEqual(p(1).window,[0 2 ; 3 4]);
assertEqual(p(1).times,{(0:2)' (0:1)'+.5 ; (3:4)' 3.5});
assertEqual(p(2).window,[0 4]);
assertEqual(p(2).times,{(0:4)' (0:3)'+.5});

function testOffset1
% Single offset
p = PointProcess('times',0:10);
p.offset = 5;
assertEqual(p.window,[0 10]);
assertEqual(p.offset,5);
assertEqual(p.times_,{(0:10)'});
assertEqual(p.times{:},(0:10)'+5);
assertEqual(p.index{:},(1:11)');
% Shouldn't change anything (AbortSet)
p.offset = 5;
assertEqual(p.window,[0 10]);
assertEqual(p.offset,5);
assertEqual(p.times_,{(0:10)'});
assertEqual(p.times{:},(0:10)'+5);
assertEqual(p.index{:},(1:11)');
% Reset offset, should not be additive
p.offset = -1;
assertEqual(p.window,[0 10]);
assertEqual(p.offset,-1);
assertEqual(p.times_,{(0:10)'});
assertEqual(p.times{:},(0:10)'-1);
assertEqual(p.index{:},(1:11)');
% Set inclusive window and check everything, doesn't change anything since
% window was already inclusive
p.setInclusiveWindow;
assertEqual(p.window,[0 10]);
assertEqual(p.offset,-1);
assertEqual(p.times_,{(0:10)'});
assertEqual(p.times{:},(0:10)'-1);
assertEqual(p.index{:},(1:11)');
% Issue a reset and check again
p.reset;
assertEqual(p.window,[0 10]);
assertEqual(p.offset,0);
assertEqual(p.times_,{(0:10)'});
assertEqual(p.times{:},(0:10)');
assertEqual(p.index{:},(1:11)');

function testOffset1_multi
% Single offset
p = PointProcess({1:10 [1:10]-.5});
p.offset = 5;
assertEqual(p.window,[0.5 10]);
assertEqual(p.offset,5);
assertEqual(p.times_,{(1:10)' (1:10)'-.5});
assertEqual(p.times,{(1:10)'+5 (1:10)'-.5+5});
assertEqual(p.index,{(1:10)' (1:10)'});
% Shouldn't change anything (AbortSet)
p.offset = 5;
assertEqual(p.window,[0.5 10]);
assertEqual(p.offset,5);
assertEqual(p.times_,{(1:10)' (1:10)'-.5});
assertEqual(p.times,{(1:10)'+5 (1:10)'-.5+5});
assertEqual(p.index,{(1:10)' (1:10)'});
% Reset offset, should not be additive
p.offset = -1;
assertEqual(p.window,[0.5 10]);
assertEqual(p.offset,-1);
assertEqual(p.times_,{(1:10)' (1:10)'-.5});
assertEqual(p.times,{(1:10)'-1 (1:10)'-.5-1});
assertEqual(p.index,{(1:10)' (1:10)'});
% Set inclusive window and check everything, doesn't change anything since
% window was already inclusive
p.setInclusiveWindow;
assertEqual(p.window,[0.5 10]);
assertEqual(p.offset,-1);
assertEqual(p.times_,{(1:10)' (1:10)'-.5});
assertEqual(p.times,{(1:10)'-1 (1:10)'-.5-1});
assertEqual(p.index,{(1:10)' (1:10)'});
% Issue a reset and check again
p.reset;
assertEqual(p.window,[0.5 10]);
assertEqual(p.offset,0);
assertEqual(p.times_,{(1:10)' (1:10)'-.5});
assertEqual(p.times,{(1:10)' (1:10)'-.5});
assertEqual(p.index,{(1:10)' (1:10)'});

function testSetOffset
p = PointProcess(1:10);
p.setOffset(5);
assertEqual(p.offset,5);
assertEqual(p.times{1},5+(1:10)');

p.setWindow([1 5;6 10]);
p.setOffset(5);
assertEqual(p.offset,[5 5]');
assertEqual(p.times{1},5+(1:5)');
assertEqual(p.times{2},5+(6:10)');

p.setOffset([1 5]);
assertEqual(p.offset,[1 5]');
assertEqual(p.times{1},1+(1:5)');
assertEqual(p.times{2},5+(6:10)');

f = @() p.setOffset([1 2 3]);
assertExceptionThrown(f,'Process:checkOffset:InputFormat')

f = @() p.setOffset('dog');
assertExceptionThrown(f,'Process:setOffset:InputFormat')

function testSetOffset_multi
p = PointProcess({1:10 [1:10]-.5});
p.setOffset(5);
assertEqual(p.offset,5);
assertEqual(p.times,{(1:10)'+5 (1:10)'-.5+5});

p.setWindow([1 5;6 10]);
p.setOffset(5);
assertEqual(p.offset,[5 5]');
assertEqual(p.times,{(1:5)'+5 (2:5)'-.5+5; (6:10)'+5 (7:10)'-.5+5});

p.setOffset([1 5]);
assertEqual(p.offset,[1 5]');
assertEqual(p.times,{(1:5)'+1 (2:5)'-.5+1; (6:10)'+5 (7:10)'-.5+5});

function testInclusiveWindow
p = PointProcess('times',1:10,'values',{{'1' '2' '3' '4' '5' '6' '7' '8' '9' '10'}});
assertEqual(p.window,[1 10]);
p.window = [1 5];
assertEqual(p.window,[1 5]);
assertEqual(p.times,{(1:5)'});
assertEqual(p.values,{{'1' '2' '3' '4' '5'}'});

p.setInclusiveWindow();
assertEqual(p.window,[1 10]);
assertEqual(p.times,{(1:10)'});
assertEqual(p.values,{{'1' '2' '3' '4' '5' '6' '7' '8' '9' '10'}'});

p.window = [1 5];
p + 10;
assertEqual(p.window,[1 5]);
assertEqual(p.times,{(1:5)'+10});
assertEqual(p.values,{{'1' '2' '3' '4' '5'}'});

% Forces an offset of zero
p.setInclusiveWindow();
assertEqual(p.times,{(1:10)'});
assertEqual(p.values,{{'1' '2' '3' '4' '5' '6' '7' '8' '9' '10'}'});
assertEqual(p.offset,0);

function testInclusiveWindow_multi
p = PointProcess('times',{1:10 (1:10)-.5},'values',{1:10 (1:10)-.5});
assertEqual(p.window,[.5 10]);
p.window = [1 5];
assertEqual(p.window,[1 5]);
assertEqual(p.times,{(1:5)' (2:5)'-.5});
assertEqual(p.values,{(1:5)' (2:5)'-.5});

p.setInclusiveWindow();
assertEqual(p.window,[.5 10]);
assertEqual(p.times,{(1:10)' (1:10)'-.5});
assertEqual(p.values,{(1:10)' (1:10)'-.5});

p.window = [1 5];
p + 10;
assertEqual(p.window,[1 5]);
assertEqual(p.times,{(1:5)'+10 (2:5)'-.5+10});
assertEqual(p.values,{(1:5)' (2:5)'-.5});

% Forces an offset of zero
p.setInclusiveWindow();
assertEqual(p.times,{(1:10)' (1:10)'-.5});
assertEqual(p.values,{(1:10)' (1:10)'-.5});
assertEqual(p.offset,0);

function testReset
p = PointProcess('times',1:10,'window',[-10 10],'offset',5);
assertEqual(p.window,[-10 10]);
assertEqual(p.offset,5);
assertEqual(p.times{1},(1:10)'+5);
assertEqual(p.window_,[-10 10]);
assertEqual(p.offset_,5);

p.window = [0 10];
p + 10;
assertEqual(p.window,[0 10]);
assertEqual(p.offset,10);
assertEqual(p.times{1},(1:10)'+10);
assertEqual(p.window_,[-10 10]);
assertEqual(p.offset_,5);

p.reset();
assertEqual(p.window,[-10 10]);
assertEqual(p.offset,5);
assertEqual(p.times{1},(1:10)'+5);
assertEqual(p.window_,[-10 10]);
assertEqual(p.offset_,5);

function testReset_multi
p = PointProcess('times',{1:10 (1:10)-.5},'window',[-10 10],'offset',5);
assertEqual(p.window,[-10 10]);
assertEqual(p.offset,5);
assertEqual(p.times,{(1:10)'+5 (1:10)'-.5+5});
assertEqual(p.window_,[-10 10]);
assertEqual(p.offset_,5);

p.window = [0 10];
p + 10;
assertEqual(p.window,[0 10]);
assertEqual(p.offset,10);
assertEqual(p.times,{(1:10)'+10 (1:10)'-.5+10});
assertEqual(p.window_,[-10 10]);
assertEqual(p.offset_,5);

p.reset();
assertEqual(p.window,[-10 10]);
assertEqual(p.offset,5);
assertEqual(p.times,{(1:10)'+5 (1:10)'-.5+5});
assertEqual(p.window_,[-10 10]);
assertEqual(p.offset_,5);
