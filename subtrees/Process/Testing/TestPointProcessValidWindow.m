classdef TestPointProcessValidWindow < matlab.unittest.TestCase
   properties
      p
   end
   
   methods(TestMethodSetup)
      function setup(testCase)
         times = (1:10)';
         testCase.p = PointProcess('times',times);
      end
   end
   
   methods(TestMethodTeardown)
      function teardown(testCase)
         testCase.p = [];
      end
   end
   
   methods (Test)
      function singleValidWindow(testCase)
         p = testCase.p;
         p.window = [1 5];
         testCase.assertTrue(p.isValidWindow);
      end
      
      function singleInvalidWindow(testCase)
         p = testCase.p;
         p.window = [-1 5];
         testCase.assertFalse(p.isValidWindow);
      end
      
      function multiValidWindow(testCase)
         p = testCase.p;
         p.window = [1 5 ; 5 10];
         testCase.assertTrue(all(p.isValidWindow));
      end
      
      function multiInvalidWindow(testCase)
         p = testCase.p;
         p.window = [-1 5 ; 5 12.5];
         testCase.assertTrue(all(~p.isValidWindow));
      end
      
      function multiMixedValidityWindow(testCase)
         p = testCase.p;
         p.window = [-1 5 ; 0.5 5.5 ; 10 12.5];
         testCase.assertEqual(p.isValidWindow,[false ; true ; false]);
      end
      
      function objectArray(testCase)
         p = testCase.p;
         p.window = [-1 1.5];
         times = (1:10)';
         p(2) = PointProcess('times',times);
         p(2).window = [0.5 5.5];
         
         testCase.assertEqual([p.isValidWindow]',[false ; true]);
      end
   end
   
end

