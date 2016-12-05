classdef TestSampledProcessFix < matlab.unittest.TestCase
   properties
      tolType = 'AbsTol'
      tol = 1e-14;
      Fs = 1000
      p
      values
   end
   
   methods(TestMethodSetup)
      function setup(testCase)
         testCase.values = [(1:2000)' , 0.5*(1:2000)']; 
         testCase.p = SampledProcess('values',testCase.values,'Fs',testCase.Fs);
      end
   end
   
   methods(TestMethodTeardown)
      function teardown(testCase)
         testCase.p = [];
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
         times = p.times;
         win = p.window;
         p.fix();
         
         testCase.assertEqual(p.offset,0);
         testCase.assertEqual(p.window,win);
         testCase.assertEqual(p.cumulOffset,0);
         testCase.assertEqual(p.times,times,testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values{1},testCase.values,testCase.tolType,testCase.tol);
      end
      
      function fixShiftToWindow(testCase)
         p = testCase.p;
         times = p.times;
         offset = 10;
         p.offset = offset;
         p.window = [0 1];
         win = p.window;
         p.fix('shiftToWindow',true);
         
         ind = (times{1}>=win(1)) & (times{1}<=win(2));
         times{1}(~ind) = [];
         
         testCase.assertEqual(p.tStart,offset + p.window(1));
         testCase.assertEqual(p.tEnd,offset + p.window(2));
         testCase.assertEqual(p.offset,offset);
         testCase.assertEqual(p.offset_,offset);
         testCase.assertEqual(p.window,win);
         testCase.assertEqual(p.window_,win);
         testCase.assertEqual(p.cumulOffset,offset);
         testCase.assertEqual(p.times,{times{1}+offset},testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values,{testCase.values(ind,:)},testCase.tolType,testCase.tol);
      end

      function fixShiftToWindowReset(testCase)
         p = testCase.p;
         times = p.times;
         offset = 10;
         p.offset = offset;
         p.window = [0 1];
         win = p.window;
         p.fix('shiftToWindow',true);
         p.reset();
         
         ind = (times{1}>=win(1)) & (times{1}<=win(2));
         times{1}(~ind) = [];

         testCase.assertEqual(p.tStart,offset + p.window(1));
         testCase.assertEqual(p.tEnd,offset + p.window(2));
         testCase.assertEqual(p.offset,offset);
         testCase.assertEqual(p.offset_,offset);
         testCase.assertEqual(p.window,win);
         testCase.assertEqual(p.window_,win);
         testCase.assertEqual(p.cumulOffset,offset);
         testCase.assertEqual(p.times,{times{1}+offset},testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values,{testCase.values(ind,:)},testCase.tolType,testCase.tol);
      end
      
      function fixShiftToWindowFalse(testCase)
         p = testCase.p;
         times = p.times;
         origWin = p.window;
         offset = 10;
         p.offset = offset;
         p.window = [0 1];
         win = p.window;
         p.fix();
         
         ind = (times{1}>=win(1)) & (times{1}<=win(2));
         times{1}(~ind) = [];

         testCase.assertEqual(p.tStart,0);
         testCase.assertEqual(p.tEnd,1.999);
         testCase.assertEqual(p.offset,offset);
         testCase.assertEqual(p.offset_,0);
         testCase.assertEqual(p.window,win);
         testCase.assertEqual(p.window_,origWin);
         testCase.assertEqual(p.cumulOffset,offset);
         testCase.assertEqual(p.times,{times{1}+offset},testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values,{testCase.values(ind,:)},testCase.tolType,testCase.tol);
      end
      
      function fixShiftToWindowFalseReset(testCase)
         p = SampledProcess('values',testCase.values,'Fs',testCase.Fs,'offset',1);
         times = {p.times{1}-1};
         origOffset = p.offset;
         origWin = p.window;
         offset = 10;
         p.offset = offset;
         p.window = [0 1];
         win = p.window;
         p.fix();
         p.reset();
         
         % Since tEnd is not adjusted by fix() in this case, there will be 
         % NaN extension due to resetting
         ind = (times{1}>=win(1)) & (times{1}<=win(2));
         values = testCase.values;
         values(~ind,:) = NaN;

         testCase.assertEqual(p.tStart,0);
         testCase.assertEqual(p.tEnd,1.999);
         testCase.assertEqual(p.offset,origOffset);
         testCase.assertEqual(p.offset_,origOffset);
         testCase.assertEqual(p.window,origWin);
         testCase.assertEqual(p.window_,origWin);
         testCase.assertEqual(p.cumulOffset,origOffset);
         testCase.assertEqual(p.times,{times{1}+origOffset},testCase.tolType,testCase.tol);
         testCase.assertEqual(p.values,{values},testCase.tolType,testCase.tol);
      end
      
      function fixArray(testCase)
         p = testCase.p;
         p(2) = SampledProcess('values',testCase.values,'Fs',testCase.Fs);
         times = [p.times];

         origWin = {p.window};
         origOffset = {p.offset};
         
         win = {[0 1] [1 1.999]};
         p.setWindow(win);
         p.fix();

         ind = (times{1}>=win{1}(1)) & (times{1}<=win{1}(2));
         times{1}(~ind) = [];
         values1 = testCase.values;
         values1(~ind,:) = [];
         ind = (times{2}>=win{2}(1)) & (times{2}<=win{2}(2));
         times{2}(~ind) = [];
         values2 = testCase.values;
         values2(~ind,:) = [];

         testCase.assertEqual({p.offset},origOffset);
         testCase.assertEqual({p.offset_},origOffset);
         testCase.assertEqual({p.window},win);
         testCase.assertEqual({p.window_},origWin);
         testCase.assertEqual({p.cumulOffset},origOffset);
         testCase.assertEqual(p(1).times,{times{1}+origOffset{1}},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(1).values,{values1},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).times,{times{2}+origOffset{2}},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).values,{values2},testCase.tolType,testCase.tol);
      end
      
   end
end

