classdef TestPointProcessWindow < matlab.unittest.TestCase
   properties
      tolType = 'AbsTol'
      tol = eps;
   end
   
   methods (Test)
      function errorFormatScalar(testCase)
         times = (1:10)';
         p = PointProcess('times',times);
         win = 1;
         
         testCase.assertError(@() set(p,'window',win),'Process:checkWindow:InputFormat');
      end
      
      function errorFormatVector(testCase)
         times = (1:10)';
         p = PointProcess('times',times);
         win = [1 2]';
         
         testCase.assertError(@() set(p,'window',win),'Process:checkWindow:InputFormat');
      end
      
      function errorAscending(testCase)
         times = (1:10)';
         p = PointProcess('times',times);
         win = [1 -1.5];
         
         testCase.assertError(@() set(p,'window',win),'Process:checkWindow:InputValue');
      end
      
      function setterSingleValidWindow(testCase)
         times = (1:10)';
         values = (1:10)';
         p = PointProcess('times',times,'values',values);
         win = [5 10];
         
         p.window = win;
         
         ind = (times>=win(1)) & (times<=win(2));
         
         testCase.assertEqual(p.times,{times(ind)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values,{values(ind)});
      end
      
      function setSingleValidWindow(testCase)
         times = (1:10)';
         values = (1:10)';
         p = PointProcess('times',times,'values',values);
         win = [5 10];
         
         set(p,'window',win);
         
         ind = (times>=win(1)) & (times<=win(2));
         
         testCase.assertEqual(p.times,{times(ind)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values,{values(ind)});
      end
      
      function setterSingleInvalidWindow(testCase)
         times = (1:10)';
         values = (1:10)';
         p = PointProcess('times',times,'values',values);
         win = [-10 10];
         
         p.window = win;
         
         ind = (times>=win(1)) & (times<=win(2));
         
         testCase.assertEqual(p.times,{times(ind)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values,{values(ind)});
      end
      
      function setSingleInvalidWindow(testCase)
         times = (1:10)';
         values = (1:10)';
         p = PointProcess('times',times,'values',values);
         win = [-10 10];
         
         set(p,'window',win);
         
         ind = (times>=win(1)) & (times<=win(2));
         
         testCase.assertEqual(p.times,{times(ind)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values,{values(ind)});
      end
      
      function setterMultiValidWindow(testCase)
         times = (1:10)';
         values = (1:10)';
         p = PointProcess('times',times,'values',values);
         win = [1 5 ; 6 10 ; 1 10];
         nWin = size(win,1);
         
         p.window = win;
         
         for i = 1:nWin
            ind = (times>=win(i,1)) & (times<=win(i,2));
            T{i,1} = times(ind);
            V{i,1} = values(ind);
         end
         
         testCase.assertEqual(p.times,T,testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values,V);
      end
      
      function setterMultiInvalidWindow(testCase)
         times = (1:10)';
         values = (1:10)';
         p = PointProcess('times',times,'values',values);
         win = [-1 5 ; 6 11 ; 10 15];
         nWin = size(win,1);
         
         p.window = win;
         
         for i = 1:nWin
            ind = (times>=win(i,1)) & (times<=win(i,2));
            T{i,1} = times(ind);
            V{i,1} = values(ind);
         end
         
         testCase.assertEqual(p.times,T,testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values,V);
      end
      
      function rewindowSingleWindow(testCase)
         times = (1:10)';
         values = (1:10)';
         p = PointProcess('times',times,'values',values);
         win = [1 5];
         
         p.window = win;
         
         win2 = [2 4];
         p.window = win2;
         
         ind = (times>=win2(1)) & (times<=win2(2));
         
         testCase.assertEqual(p.times,{times(ind)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values,{values(ind)});
      end
      
      % rewindow single, initial valid, second invalid
      function rewindowSingleWindow2(testCase)
         times = (1:10)';
         values = (1:10)';
         p = PointProcess('times',times,'values',values);
         win = [1 5];
         
         p.window = win;
         
         win2 = [2 10];
         p.window = win2;
         
         % Times outside the previous window will be missing
         ind = (times>=max(win(1),win2(1))) & (times<=min(win(2),win2(2)));
         
         testCase.assertEqual(p.times,{times(ind)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values,{values(ind)});
      end
      
      % rewindow multi (matching nwin)
      function rewindowMultiWindow(testCase)
         times = (1:10)';
         values = (1:10)';
         p = PointProcess('times',times,'values',values);
         win = [-1 5 ; 6 11 ; 10 15];
         nWin = size(win,1);
         
         p.window = win;
         
         win2 = [2 4 ; 5 12 ; 1 10];
         p.window = win2;
         
         for i = 1:nWin
            % Times outside the previous window will be missing
            ind = (times>=max(win(i,1),win2(i,1))) & (times<=min(win(i,2),win2(i,2)));
            T{i,1} = times(ind);
            V{i,1} = values(ind);
         end
         
         testCase.assertEqual(p.times,T,testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values,V);
      end
      
      % Rewindowing with non-matching number of windows will reset the Process
      function rewindowMultiNonmatchingWindow(testCase)
         times = (1:10)';
         values = (1:10)';
         p = PointProcess('times',times,'values',values);
         win = [-1 5 ; 6 11 ; 10 15];
         
         p.window = win;
         
         win2 = [2 4 ; 5 12];
         nWin = size(win2,1);
         p.window = win2;
         
         for i = 1:nWin
            ind = (times>=win2(i,1)) & (times<=win2(i,2));
            T{i,1} = times(ind);
            V{i,1} = values(ind);
         end
         
         testCase.assertEqual(p.times,T,testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values,V);
      end
      
      % 1 PointProcess, multiple event times
      function multiEventsSingleWindow(testCase)
         times{1} = (1:10)';
         times{2} = (11:20)';
         values{1} = (1:10)';
         values{2} = (11:20)';
         p = PointProcess('times',times,'values',values);
         win = [5 15];
         nWin = size(win,1);
         nTimes = numel(times);
         
         p.window = win;
         
         for i = 1:nWin
            for j = 1:nTimes
               ind = (times{j}>=win(i,1)) & (times{j}<=win(i,2));
               T{i,j} = times{j}(ind);
               V{i,j} = values{j}(ind);
            end
         end
         
         testCase.assertEqual(p.times,T,testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values,V);
      end
      
      % array
      function setWindowWithSameArray(testCase)
         times{1} = (1:10)';
         times{2} = (11:20)';
         values{1} = (1:10)';
         values{2} = (11:20)';
         win = [5 15];
         nWin = size(win,1);
         nTimes = numel(times);
         for i = 1:nTimes
            p(i) = PointProcess('times',times{i},'values',values{i});
         end
         
         setWindow(p,win);
         
         for i = 1:nTimes
            testCase.assertEqual(p(i).window,win);
         end
      end
      
      function setWindowWithDiffArray(testCase)
         times{1} = (1:10)';
         times{2} = (11:20)';
         values{1} = (1:10)';
         values{2} = (11:20)';
         win = {[5 15] ; [0 10]};
         nWin = size(win,1);
         nTimes = numel(times);
         for i = 1:nTimes
            p(i) = PointProcess('times',times{i},'values',values{i});
         end
         
         setWindow(p,win);
         
         for i = 1:nTimes
            testCase.assertEqual(p(i).window,win{i});
         end
      end
      
      function setInclusiveWindow(testCase)
         times = (1:10)';
         values = (1:10)';
         p = PointProcess('times',times,'values',values);
         win = [1 5];
         
         p.window = win;
         p.setInclusiveWindow();
         
         testCase.assertEqual(p.window,[p.tStart p.tEnd]);
      end
   end
end

