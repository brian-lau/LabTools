
function test_suite = testWindowTimes
initTestSuite;

%% Errors
function testErrorNoArgs
% Not enough parameters to do any alignment
eventTimes = {1:10};
f = @() windowTimes(eventTimes);
assertExceptionThrown(f, 'windowTimes:InputCount');

function testErrorArrayInput
% Input as numeric array should fail
eventTimes = 1:10;
f = @() windowTimes(eventTimes,'offset',0);
assertExceptionThrown(f, 'MATLAB:invalidType');

function testErrorNonMatrixInput
% non-2d array should fail
f = @() windowTimes(cell(3,3,3),'offset',0);
assertExceptionThrown(f, 'MATLAB:expected2D');

function testErrorSync
% Bad input type for offset
eventTimes = 1:10;
f = @() windowTimes(eventTimes,'offset','1');
assertExceptionThrown(f, 'MATLAB:invalidType');

%% Make sure zero offset just gives back the same input
% Zero offset should not change anything without window
function testZeroSyncNoWindow1
eventTimes = {1:10};
aTimes = windowTimes(eventTimes,'offset',0);
assertEqual(aTimes{1},1:10);

function testZeroSyncNoWindow2
% numel(eventTimes) > 1, row vector
eventTimes = {[1:10] [20:30]};
aTimes = windowTimes(eventTimes,'offset',0);
assertEqual(aTimes{1},1:10);
assertEqual(aTimes{2},20:30);

function testZeroSyncNoWindow3
% numel(eventTimes) > 1, column vector
eventTimes = {[1:10] ; [20:30]};
aTimes = windowTimes(eventTimes,'offset',0);
assertEqual(aTimes{1},1:10);
assertEqual(aTimes{2},20:30);

function testZeroSyncNoWindow4
% numel(eventTimes) > 1, 2d matrix
eventTimes = {[1:10] [20:30] ; [30:35] [50:59]};
aTimes = windowTimes(eventTimes,'offset',0);
assertEqual(aTimes{1,1},1:10);
assertEqual(aTimes{1,2},20:30);
assertEqual(aTimes{2,1},30:35);
assertEqual(aTimes{2,2},50:59);

%% Check offset shifts eventTimes appropriately
function testSyncNoWindow1
eventTimes = {1:10};
aTimes = windowTimes(eventTimes,'offset',10);
assertEqual(aTimes{1},(1:10) + 10);
aTimes = windowTimes(eventTimes,'offset',-10);
assertEqual(aTimes{1},(1:10) - 10);

function testSyncNoWindow2
% numel(eventTimes) > 1, row vector
eventTimes = {[1:10] [20:30]};
aTimes = windowTimes(eventTimes,'offset',10);
assertEqual(aTimes{1},(1:10) + 10);
assertEqual(aTimes{2},(20:30) + 10);
aTimes = windowTimes(eventTimes,'offset',-10);
assertEqual(aTimes{1},(1:10) - 10);
assertEqual(aTimes{2},(20:30) - 10);

function testSyncNoWindow3
% numel(eventTimes) > 1, column vector
eventTimes = {[1:10] ; [20:30]};
aTimes = windowTimes(eventTimes,'offset',10);
assertEqual(aTimes{1},(1:10) + 10);
assertEqual(aTimes{2},(20:30) + 10);
aTimes = windowTimes(eventTimes,'offset',-10);
assertEqual(aTimes{1},(1:10) - 10);
assertEqual(aTimes{2},(20:30) - 10);

function testSyncNoWindow4
% numel(eventTimes) > 1, 2d matrix
eventTimes = {[1:10] [20:30] ; [30:35] [50:59]};
aTimes = windowTimes(eventTimes,'offset',10);
assertEqual(aTimes{1,1},(1:10) + 10);
assertEqual(aTimes{1,2},(20:30) + 10);
assertEqual(aTimes{2,1},(30:35) + 10);
assertEqual(aTimes{2,2},(50:59) + 10);
aTimes = windowTimes(eventTimes,'offset',-10);
assertEqual(aTimes{1,1},(1:10) - 10);
assertEqual(aTimes{1,2},(20:30) - 10);
assertEqual(aTimes{2,1},(30:35) - 10);
assertEqual(aTimes{2,2},(50:59) - 10);

%% Check returned window when we didn't include one as an input, zero offset
function testZeroSyncNoWindowReturnWindow1
% Returning a window when numel(eventTimes) = 1 should be [min max]
eventTimes = {1:10};
[~,aWindow] = windowTimes(eventTimes,'offset',0);
assertEqual(aWindow,[1 10]);

function testZeroSyncNoWindowReturnWindow2
% Returning a window when numel(eventTimes) > 1 should be [min max] across 
% all eventTimes
eventTimes = {[1:10] [20:30]};
[~,aWindow] = windowTimes(eventTimes,'offset',0);
assertEqual(aWindow,[1 30]);

function testZeroSyncNoWindowReturnWindow3
% Returning a window when numel(eventTimes) > 1 should be [min max] across 
% all eventTimes.
% When eventTimes is a row vector, we return a [1x2] window since we only
% return one window per row of eventTimes.
eventTimes = {[1:10]' [20:30]'};
[~,aWindow] = windowTimes(eventTimes,'offset',0);
assertEqual(aWindow,[1 30]);

function testZeroSyncNoWindowReturnWindow4
% Returning a window when numel(eventTimes) > 1 should be [min max] across 
% all eventTimes
% When eventTimes is a column vector, we return a [nRows x 2] window
eventTimes = {[1:10]' ; [20:30]'};
[~,aWindow] = windowTimes(eventTimes,'offset',0);
assertEqual(aWindow(1,:),[1 30]);
assertEqual(aWindow(2,:),[1 30]);

function testZeroSyncNoWindowReturnWindow5
% Returning a window when numel(eventTimes) > 1 should be [min max] across 
% all eventTimes
% When eventTimes is a 2d matrix, we return a [nRows x 2] window
eventTimes = {[1:10] [20:30] ; [30:40] [50:60]};
[~,aWindow] = windowTimes(eventTimes,'offset',0);
assertEqual(aWindow(1,:),[1 60]);
assertEqual(aWindow(2,:),[1 60]);

%% Check windowing without offset
function testZeroSyncWindow1
eventTimes = {1:10};
aTimes = windowTimes(eventTimes,'window',[4 10]);
assertEqual(aTimes{1},4:10);
aTimes = windowTimes(eventTimes,'window',[-10 0]);
assertEqual(numel(aTimes{1}),0);
aTimes = windowTimes(eventTimes,'window',[10 20]);
assertEqual(aTimes{1},10);

function testZeroSyncWindow2
% numel(eventTimes) > 1, row vector
eventTimes = {[1:10] [20:30]};
aTimes = windowTimes(eventTimes,'window',[4 20]);
assertEqual(aTimes{1},4:10);
assertEqual(aTimes{2},20);
aTimes = windowTimes(eventTimes,'window',[-10 0]);
assertEqual(numel(aTimes{1}),0);
assertEqual(numel(aTimes{2}),0);
aTimes = windowTimes(eventTimes,'window',[10 50]);
assertEqual(aTimes{1},10);
assertEqual(aTimes{2},20:30);

function testZeroSyncWindow3
% numel(eventTimes) > 1, column vector
eventTimes = {[1:10] ; [20:30]};
aTimes = windowTimes(eventTimes,'window',[4 20]);
assertEqual(aTimes{1},4:10);
assertEqual(aTimes{2},20);
aTimes = windowTimes(eventTimes,'window',[-10 0]);
assertEqual(numel(aTimes{1}),0);
assertEqual(numel(aTimes{2}),0);
aTimes = windowTimes(eventTimes,'window',[10 50]);
assertEqual(aTimes{1},10);
assertEqual(aTimes{2},20:30);

function testZeroSyncWindow4
% numel(eventTimes) > 1, 2d matrix
eventTimes = {[1:10] [20:30] ; [30:35] [50:59]};
aTimes = windowTimes(eventTimes,'window',[4 20]);
assertEqual(aTimes{1,1},4:10);
assertEqual(aTimes{1,2},20);
assertEqual(numel(aTimes{2,1}),0);
assertEqual(numel(aTimes{2,2}),0);
aTimes = windowTimes(eventTimes,'window',[-10 0]);
assertEqual(numel(aTimes{1,1}),0);
assertEqual(numel(aTimes{1,2}),0);
assertEqual(numel(aTimes{2,1}),0);
assertEqual(numel(aTimes{2,2}),0);
aTimes = windowTimes(eventTimes,'window',[10 50]);
assertEqual(aTimes{1,1},10);
assertEqual(aTimes{1,2},20:30);
assertEqual(aTimes{2,1},30:35);
assertEqual(aTimes{2,2},50);

%% Check windowing with offset
function testSyncWindow1
eventTimes = {1:10};
aTimes = windowTimes(eventTimes,'window',[4 10],'offset',1);
assertEqual(aTimes{1},(4:10) + 1);
aTimes = windowTimes(eventTimes,'window',[4 10],'offset',-1);
assertEqual(aTimes{1},(4:10) - 1);
aTimes = windowTimes(eventTimes,'window',[-10 0],'offset',1);
assertEqual(numel(aTimes{1}),0);
aTimes = windowTimes(eventTimes,'window',[10 20],'offset',1);
assertEqual(aTimes{1},11);
aTimes = windowTimes(eventTimes,'window',[10 20],'offset',-1);
assertEqual(aTimes{1},9);

function testSyncWindow2
% numel(eventTimes) > 1, row vector
eventTimes = {[1:10] [20:30]};
aTimes = windowTimes(eventTimes,'window',[4 20],'offset',1);
assertEqual(aTimes{1},(4:10) + 1);
assertEqual(aTimes{2},20 + 1);
aTimes = windowTimes(eventTimes,'window',[4 20],'offset',-1);
assertEqual(aTimes{1},(4:10) - 1);
assertEqual(aTimes{2},20 - 1);
aTimes = windowTimes(eventTimes,'window',[-10 0],'offset',1);
assertEqual(numel(aTimes{1}),0);
assertEqual(numel(aTimes{2}),0);
aTimes = windowTimes(eventTimes,'window',[-10 0],'offset',-1);
assertEqual(numel(aTimes{1}),0);
assertEqual(numel(aTimes{2}),0);
aTimes = windowTimes(eventTimes,'window',[10 50],'offset',1);
assertEqual(aTimes{1},10 + 1);
assertEqual(aTimes{2},(20:30) + 1);
aTimes = windowTimes(eventTimes,'window',[10 50],'offset',-1);
assertEqual(aTimes{1},10 - 1);
assertEqual(aTimes{2},(20:30) - 1);

function testSyncWindow3
% numel(eventTimes) > 1, column vector
eventTimes = {[1:10] ; [20:30]};
aTimes = windowTimes(eventTimes,'window',[4 20],'offset',1);
assertEqual(aTimes{1},(4:10) + 1);
assertEqual(aTimes{2},20 + 1);
aTimes = windowTimes(eventTimes,'window',[4 20],'offset',-1);
assertEqual(aTimes{1},(4:10) - 1);
assertEqual(aTimes{2},20 - 1);
aTimes = windowTimes(eventTimes,'window',[-10 0],'offset',1);
assertEqual(numel(aTimes{1}),0);
assertEqual(numel(aTimes{2}),0);
aTimes = windowTimes(eventTimes,'window',[-10 0],'offset',-1);
assertEqual(numel(aTimes{1}),0);
assertEqual(numel(aTimes{2}),0);
aTimes = windowTimes(eventTimes,'window',[10 50],'offset',1);
assertEqual(aTimes{1},10 + 1);
assertEqual(aTimes{2},(20:30) + 1);
aTimes = windowTimes(eventTimes,'window',[10 50],'offset',-1);
assertEqual(aTimes{1},10 - 1);
assertEqual(aTimes{2},(20:30) - 1);

function testSyncWindow4
% numel(eventTimes) > 1, 2d matrix
eventTimes = {[1:10] [20:30] ; [30:35] [50:59]};
aTimes = windowTimes(eventTimes,'window',[4 20],'offset',1);
assertEqual(aTimes{1,1},(4:10) + 1);
assertEqual(aTimes{1,2},20 + 1);
assertEqual(numel(aTimes{2,1}),0);
assertEqual(numel(aTimes{2,2}),0);
aTimes = windowTimes(eventTimes,'window',[4 20],'offset',-1);
assertEqual(aTimes{1,1},(4:10) - 1);
assertEqual(aTimes{1,2},20 - 1);
assertEqual(numel(aTimes{2,1}),0);
assertEqual(numel(aTimes{2,2}),0);
aTimes = windowTimes(eventTimes,'window',[-10 0],'offset',1);
assertEqual(numel(aTimes{1,1}),0);
assertEqual(numel(aTimes{1,2}),0);
assertEqual(numel(aTimes{2,1}),0);
assertEqual(numel(aTimes{2,2}),0);
aTimes = windowTimes(eventTimes,'window',[-10 0],'offset',-1);
assertEqual(numel(aTimes{1,1}),0);
assertEqual(numel(aTimes{1,2}),0);
assertEqual(numel(aTimes{2,1}),0);
assertEqual(numel(aTimes{2,2}),0);
aTimes = windowTimes(eventTimes,'window',[10 50],'offset',1);
assertEqual(aTimes{1,1},10 + 1);
assertEqual(aTimes{1,2},(20:30) + 1);
assertEqual(aTimes{2,1},(30:35) + 1);
assertEqual(aTimes{2,2},50 + 1);
aTimes = windowTimes(eventTimes,'window',[10 50],'offset',-1);
assertEqual(aTimes{1,1},10 - 1);
assertEqual(aTimes{1,2},(20:30) - 1);
assertEqual(aTimes{2,1},(30:35) - 1);
assertEqual(aTimes{2,2},50 - 1);

%% Check returned window when we include one as an input, with offset
function testSyncWindowReturnWindow1
eventTimes = {1:10};
[aTimes,aWindow] = windowTimes(eventTimes,'window',[4 10],'offset',1);
assertEqual(aTimes{1},[4:10] + 1);
assertEqual(aWindow,[4 10] + 1);
[aTimes,aWindow] = windowTimes(eventTimes,'window',[4 10],'offset',-1);
assertEqual(aTimes{1},[4:10] - 1);
assertEqual(aWindow,[4 10] - 1);
[aTimes,aWindow] = windowTimes(eventTimes,'window',[-10 0],'offset',1);
assertEqual(numel(aTimes{1}),0);
assertEqual(aWindow,[-10 0] + 1);
[aTimes,aWindow] = windowTimes(eventTimes,'window',[10 20],'offset',1);
assertEqual(aTimes{1},10 + 1);
assertEqual(aWindow,[10 20] + 1);
[aTimes,aWindow] = windowTimes(eventTimes,'window',[10 20],'offset',-1);
assertEqual(aTimes{1},10 - 1);
assertEqual(aWindow,[10 20] - 1);

[aTimes,aWindow] = windowTimes(eventTimes,'window',[4 10],'offset',1,'windowThenOffset',false);
assertEqual(aTimes{1},[4:10]);
assertEqual(aWindow,[4 10]);
[aTimes,aWindow] = windowTimes(eventTimes,'window',[4 10],'offset',-1,'windowThenOffset',false);
assertEqual(aTimes{1},[4:9]);
assertEqual(aWindow,[4 10]);
[aTimes,aWindow] = windowTimes(eventTimes,'window',[-10 0],'offset',1,'windowThenOffset',false);
assertEqual(numel(aTimes{1}),0);
assertEqual(aWindow,[-10 0]);
[aTimes,aWindow] = windowTimes(eventTimes,'window',[10 20],'offset',1,'windowThenOffset',false);
assertEqual(aTimes{1},[10:11]);
assertEqual(aWindow,[10 20]);
[aTimes,aWindow] = windowTimes(eventTimes,'window',[10 20],'offset',-1,'windowThenOffset',false);
assertEqual(numel(aTimes{1}),0);
assertEqual(aWindow,[10 20]);

%% Inputs are returned in same format
function testInputOrientation
eventTimes = {[1:10]' [20:30]};
[aTimes,aWindow] = windowTimes(eventTimes,'offset',0);
assertEqual(size(aTimes{1},1),size(eventTimes{1},1));
assertEqual(size(aTimes{1},2),size(eventTimes{1},2));
assertEqual(size(aTimes{2},1),size(eventTimes{2},1));
assertEqual(size(aTimes{2},2),size(eventTimes{2},2));

% %% check column indexing
% 
% %% Check nan-skipping










