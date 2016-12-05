classdef TestPointProcessChop < matlab.unittest.TestCase
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
      function errorNonScalar(testCase)
         p = testCase.p;
         p(2) = PointProcess();

         testCase.assertError(@() chop(p),'Process:chop:InputCount');
      end
      
      function chopShiftToWindow(testCase)
         p = testCase.p;
         p.window = [1 10; 11 20];
         p.chop;
         
         testCase.assertEqual([p.offset],[0 0]);
         testCase.assertEqual([p.cumulOffset],[0 0]);
         testCase.assertEqual(p(1).times,{(0:9)' zeros(0,1)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).times,{zeros(0,1) (0:9)'},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(1).values,{(1:10)' zeros(0,1)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).values,{zeros(0,1) (11:20)'},testCase.tolType,testCase.tol);
      end

      function chopShiftToWindowFalse(testCase)
         p = testCase.p;
         p.window = [1 10; 11 20];
         p.chop('shiftToWindow',false);
         
         testCase.assertEqual([p.offset],[0 0]);
         testCase.assertEqual([p.cumulOffset],[0 0]);
         testCase.assertEqual(p(1).times,{(1:10)' zeros(0,1)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).times,{zeros(0,1) (11:20)'},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(1).values,{(1:10)' zeros(0,1)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).values,{zeros(0,1) (11:20)'},testCase.tolType,testCase.tol);
      end

      function chopCopyInfo(testCase)
         p = testCase.p;
         info = p.info;
         p.window = [1 10; 11 20];
         p.chop();
         
         testCase.assertFalse(p(1).info==info);
         testCase.assertFalse(p(2).info==info);
      end
      
      function chopCopyInfoFalse(testCase)
         p = testCase.p;
         info = p.info;
         p.window = [1 10; 11 20];
         p.chop('copyInfo',false);
         
         testCase.assertTrue(p(1).info==info);
         testCase.assertTrue(p(2).info==info);
      end
      
      function chopCopyLabelFalse(testCase)
         p = testCase.p;
         info = p.info;
         p.window = [1 10; 11 20];
         p.chop();
         
         testCase.assertTrue(p(1).labels(1)==p(2).labels(1));
         testCase.assertTrue(p(1).labels(2)==p(2).labels(2));
      end
      
      function chopCopyLabel(testCase)
         p = testCase.p;
         info = p.info;
         p.window = [1 10; 11 20];
         p.chop('copyLabel',true);
         
         testCase.assertFalse(p(1).labels(1)==p(2).labels(1));
         testCase.assertFalse(p(1).labels(2)==p(2).labels(2));
      end
      
      function chopWithOffset(testCase)
         p = testCase.p;
         p.window = [1 10; 11 20];
         p.offset = [1 2];
         p.chop();

         testCase.assertEqual([p.offset],[1 2]);
         testCase.assertEqual([p.cumulOffset],[1 2]);
         testCase.assertEqual(p(1).times,{1+(0:9)' zeros(0,1)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).times,{zeros(0,1) 2+(0:9)'},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(1).values,{(1:10)' zeros(0,1)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).values,{zeros(0,1) (11:20)'},testCase.tolType,testCase.tol);
      end
      
      function chopWithOffset2(testCase)
         p = testCase.p;
         p.window = [1 10; 11 20];
         p.offset = [1 2];
         p.offset = [1 2];
         p.chop();

         testCase.assertEqual([p.offset],[1 2]);
         testCase.assertEqual([p.cumulOffset],[2 4]);
         testCase.assertEqual(p(1).times,{2+(0:9)' zeros(0,1)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).times,{zeros(0,1) 4+(0:9)'},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(1).values,{(1:10)' zeros(0,1)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).values,{zeros(0,1) (11:20)'},testCase.tolType,testCase.tol);
      end
      
      function chopAfterSubset(testCase)
         p = testCase.p;
         p.window = [1 10; 11 20];
         p.subset(2);
         p.chop();

         testCase.assertTrue(numel(p(1).labels)==1);
         testCase.assertTrue(numel(p(2).labels)==1);
         testCase.assertTrue(p(1).labels==p(2).labels);
         testCase.assertEqual(p(1).times,{zeros(0,1)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).times,{(0:9)'},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(1).values,{zeros(0,1)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).values,{(11:20)'},testCase.tolType,testCase.tol);
      end      
   end
   
end

