classdef TestSampledProcessValidWindow < matlab.unittest.TestCase
   properties
      s
      Fs = 1000
   end
   
   methods(TestMethodSetup)
      function setup(testCase)
         values = (0:2*ceil(testCase.Fs))'; % times range from 0 to at least 2 seconds
         testCase.s = SampledProcess('values',values,'Fs',testCase.Fs);
      end
   end
   
   methods(TestMethodTeardown)
      function teardown(testCase)
         testCase.s = [];
      end
   end
   
   methods (Test)
      function singleValidWindow(testCase)
         s = testCase.s;
         s.window = [1 1.5];
         testCase.assertTrue(s.isValidWindow);
      end
      
      function singleInvalidWindow(testCase)
         s = testCase.s;
         s.window = [-1 1.5];
         testCase.assertFalse(s.isValidWindow);
      end
      
      function multiValidWindow(testCase)
         s = testCase.s;
         s.window = [1 1.5 ; 0.5 1.75];
         testCase.assertTrue(all(s.isValidWindow));
      end
      
      function multiInvalidWindow(testCase)
         s = testCase.s;
         s.window = [-1 1.5 ; 0 2.5];
         testCase.assertTrue(all(~s.isValidWindow));
      end
      
      function multiMixedValidityWindow(testCase)
         s = testCase.s;
         s.window = [-1 1.5 ; 0.5 1.5 ; 0 2.5];
         testCase.assertEqual(s.isValidWindow,[false ; true ; false]);
      end
      
      function objectArray(testCase)
         s = testCase.s;
         s.window = [-1 1.5];
         s(2) = SampledProcess('values',ones(size(s.values{1})),'Fs',testCase.Fs);
         s(2).window = [0.5 1.5];
         
         testCase.assertEqual([s.isValidWindow]',[false ; true]);
      end
   end
   
end

