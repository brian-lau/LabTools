classdef TestPointProcessFix < matlab.unittest.TestCase
   properties
      tolType = 'AbsTol'
      tol = eps;
      p
      times
      values
   end
   
   methods(TestMethodSetup)
      function setup(testCase)
         testCase.times = {(1:10)' (11:20)'};
         testCase.values = {(1:10)' (11:20)'};
         testCase.p = PointProcess('times',testCase.times,'values',testCase.values);
      end
   end
   
   methods(TestMethodTeardown)
      function teardown(testCase)
         testCase.p = [];
         testCase.times = [];
         testCase.values = [];
      end
   end
   
   methods (Test)
      function errorMultipleWindow(testCase)
         p = testCase.p;
         p.window = [0 10; 11 20];

         testCase.assertError(@() fix(p),'Process:fix:InputFormat');
      end
      
      function fixUnchanged(testCase)
         p = testCase.p;
         win = p.window;
         p.fix();
         
         testCase.assertEqual(p.offset,0);
         testCase.assertEqual(p.window,win);
         testCase.assertEqual(p.cumulOffset,0);
         testCase.assertEqual(p.times,testCase.times,testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values,testCase.values,testCase.tolType,testCase.tol);
      end
      
      function fixShiftToWindow(testCase)
         p = testCase.p;
         offset = 10;
         p.offset = offset;
         p.window = [1 10];
         win = p.window;
         p.fix('shiftToWindow',true);
         
         testCase.assertEqual(p.tStart,offset + p.window(1));
         testCase.assertEqual(p.tEnd,offset + p.window(2));
         testCase.assertEqual(p.offset,offset);
         testCase.assertEqual(p.offset_,offset);
         testCase.assertEqual(p.window,win);
         testCase.assertEqual(p.window_,win);
         testCase.assertEqual(p.cumulOffset,offset);
         testCase.assertEqual(p.times,{testCase.times{1}+offset zeros(0,1)},...
            testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values,{testCase.values{1} zeros(0,1)},testCase.tolType,testCase.tol);
      end
      
      function fixShiftToWindowReset(testCase)
         p = testCase.p;
         offset = 10;
         p.offset = offset;
         p.window = [1 10];
         win = p.window;
         p.fix('shiftToWindow',true);
         p.reset();
         
         testCase.assertEqual(p.tStart,offset + p.window(1));
         testCase.assertEqual(p.tEnd,offset + p.window(2));
         testCase.assertEqual(p.offset,offset);
         testCase.assertEqual(p.offset_,offset);
         testCase.assertEqual(p.window,win);
         testCase.assertEqual(p.window_,win);
         testCase.assertEqual(p.cumulOffset,offset);
         testCase.assertEqual(p.times,{testCase.times{1}+offset zeros(0,1)},...
            testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values,{testCase.values{1} zeros(0,1)},testCase.tolType,testCase.tol);
      end
      
      function fixShiftToWindowFalse(testCase)
         p = testCase.p;
         origWin = p.window;
         offset = 10;
         p.offset = offset;
         p.window = [1 10];
         win = p.window;
         p.fix();
         
         testCase.assertEqual(p.tStart,0);
         testCase.assertEqual(p.tEnd,20);
         testCase.assertEqual(p.offset,offset);
         testCase.assertEqual(p.offset_,0);
         testCase.assertEqual(p.window,win);
         testCase.assertEqual(p.window_,origWin);
         testCase.assertEqual(p.cumulOffset,offset);
         testCase.assertEqual(p.times,{testCase.times{1}+offset zeros(0,1)},...
            testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values,{testCase.values{1} zeros(0,1)},testCase.tolType,testCase.tol);
      end
      
      function fixShiftToWindowFalseReset(testCase)
         p = PointProcess('times',testCase.times,'values',testCase.values,'offset',10);
         origWin = p.window;
         origOffset = p.offset;
         offset = 10;
         p.offset = offset;
         p.window = [1 10];
         win = p.window;
         p.fix();
         p.reset();
         
         testCase.assertEqual(p.tStart,0);
         testCase.assertEqual(p.tEnd,20);
         testCase.assertEqual(p.offset,origOffset);
         testCase.assertEqual(p.offset_,origOffset);
         testCase.assertEqual(p.window,origWin);
         testCase.assertEqual(p.window_,origWin);
         testCase.assertEqual(p.cumulOffset,origOffset);
         testCase.assertEqual(p.times,{testCase.times{1}+origOffset zeros(0,1)},...
            testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values,{testCase.values{1} zeros(0,1)},testCase.tolType,testCase.tol);
      end
      
      function fixArray(testCase)
         p = testCase.p;
         p(2) = PointProcess('times',testCase.times,'values',testCase.values,'offset',10);
         
         origWin = {p.window};
         origOffset = {p.offset};
         
         win = {[1 10] [11 20]};
         p.setWindow(win);
         p.fix();

         testCase.assertEqual({p.offset},origOffset);
         testCase.assertEqual({p.offset_},origOffset);
         testCase.assertEqual({p.window},win);
         testCase.assertEqual({p.window_},origWin);
         testCase.assertEqual({p.cumulOffset},origOffset);
         testCase.assertEqual(p(1).times,{testCase.times{1}+origOffset{1} zeros(0,1)},...
            testCase.tolType,testCase.tol);
         testCase.assertEqual(p(1).values,{testCase.values{1} zeros(0,1)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).times,{zeros(0,1) testCase.times{2}+origOffset{2}},...
            testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).values,{zeros(0,1) testCase.values{2}},testCase.tolType,testCase.tol);
      end

   end
   
end

