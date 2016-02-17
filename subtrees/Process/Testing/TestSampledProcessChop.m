classdef TestSampledProcessChop < matlab.unittest.TestCase
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
      function errorNonScalar(testCase)
         p = testCase.p;
         p(2) = SampledProcess();

         testCase.assertError(@() chop(p),'Process:chop:InputCount');
      end
      
      function chopShiftToWindow(testCase)
         p = testCase.p;
         dt = p.dt;
         p.window = [0 1; 1 1.999];
         p.chop;
         
         testCase.assertEqual([p.offset],[0 0]);
         testCase.assertEqual([p.cumulOffset],[0 0]);
         testCase.assertEqual(p(1).times,{(0:dt:1)'},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).times,{(0:dt:.999)'},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(1).values,{testCase.values(1:1001,:)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).values,{testCase.values(1001:2000,:)},testCase.tolType,testCase.tol);
      end

      function chopShiftToWindowFalse(testCase)
         p = testCase.p;
         dt = p.dt;
         p.window = [0 1; 1 1.999];
         p.chop('shiftToWindow',false);
         
         testCase.assertEqual([p.offset],[0 0]);
         testCase.assertEqual([p.cumulOffset],[0 0]);
         testCase.assertEqual(p(1).times,{(0:dt:1)'},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).times,{(1:dt:1.999)'},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(1).values,{testCase.values(1:1001,:)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).values,{testCase.values(1001:2000,:)},testCase.tolType,testCase.tol);
      end

      function chopCopyInfo(testCase)
         p = testCase.p;
         info = p.info;
         p.window = [0 1; 1 1.999];
         p.chop;
         
         testCase.assertFalse(p(1).info==info);
         testCase.assertFalse(p(2).info==info);
      end
      
      function chopCopyInfoFalse(testCase)
         p = testCase.p;
         info = p.info;
         p.window = [0 1; 1 1.999];
         p.chop('copyInfo',false);
         
         testCase.assertTrue(p(1).info==info);
         testCase.assertTrue(p(2).info==info);
      end
      
      function chopCopyLabelFalse(testCase)
         p = testCase.p;
         info = p.info;
         p.window = [0 1; 1 1.999];
         p.chop();
         
         testCase.assertTrue(p(1).labels(1)==p(2).labels(1));
         testCase.assertTrue(p(1).labels(2)==p(2).labels(2));
      end
      
      function chopCopyLabel(testCase)
         p = testCase.p;
         info = p.info;
         p.window = [0 1; 1 1.999];
         p.chop('copyLabel',true);
         
         testCase.assertFalse(p(1).labels(1)==p(2).labels(1));
         testCase.assertFalse(p(1).labels(2)==p(2).labels(2));
      end
      
      function chopWithOffset(testCase)
         p = testCase.p;
         dt = p.dt;
         p.window = [0 1; 1 1.999];
         p.offset = [1 2];
         p.chop();

         testCase.assertEqual([p.offset],[1 2]);
         testCase.assertEqual([p.cumulOffset],[1 2]);
         testCase.assertEqual(p(1).times,{1+(0:dt:1)'},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).times,{2+(0:dt:.999)'},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(1).values,{testCase.values(1:1001,:)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).values,{testCase.values(1001:2000,:)},testCase.tolType,testCase.tol);
      end
      
      function chopWithOffset2(testCase)
         p = testCase.p;
         dt = p.dt;
         p.window = [0 1; 1 1.9999]; % NOTE 4th decimal place is for numerical rounding error
         p.offset = [1 2];
         p.offset = [1 2];
         p.chop();

         testCase.assertEqual([p.offset],[1 2]);
         testCase.assertEqual([p.cumulOffset],[2 4]);
         testCase.assertEqual(p(1).times,{2+(0:dt:1)'},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).times,{4+(0:dt:.999)'},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(1).values,{testCase.values(1:1001,:)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).values,{testCase.values(1001:2000,:)},testCase.tolType,testCase.tol);
      end
      
      function chopAfterSubset(testCase)
         p = testCase.p;
         dt = p.dt;
         p.window = [0 1; 1 1.999];
         p.subset(2);
         p.chop();

         testCase.assertTrue(numel(p(1).labels)==1);
         testCase.assertTrue(numel(p(2).labels)==1);
         testCase.assertTrue(p(1).labels==p(2).labels);
         testCase.assertEqual(p(1).times,{(0:dt:1)'},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).times,{(0:dt:.999)'},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(1).values,{testCase.values(1:1001,2)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).values,{testCase.values(1001:2000,2)},testCase.tolType,testCase.tol);
      end      
   end
   
end

