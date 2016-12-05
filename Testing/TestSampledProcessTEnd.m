% should setting tEnd/tEnd trigger reload from values_, or
% setInclusiveWindow?
classdef TestSampledProcessTEnd < matlab.unittest.TestCase
   properties
      tolType = 'AbsTol'
      tol = eps;
      Fs = 1000
      s
      values
   end
   
   methods(TestMethodSetup)
      function setup(testCase)
         testCase.values = (0:2*ceil(testCase.Fs))'; % times range from 0 to at least 2 seconds
         testCase.s = SampledProcess('values',testCase.values,'Fs',testCase.Fs);
      end
   end
   
   methods(TestMethodTeardown)
      function teardown(testCase)
         testCase.s = [];
         testCase.values = [];
      end
   end
   
   methods (Test)
      function errorNotScalar(testCase)
         s = testCase.s;
         tEnd = [3 4];

         testCase.assertError(@() set(s,'tEnd',tEnd),'SampledProcess:tEnd:InputFormat');
      end
      
      function errorLessThanTStart(testCase)
         s = testCase.s;
         tEnd = -1;

         testCase.assertError(@() set(s,'tEnd',tEnd),'SampledProcess:tEnd:InputValue');
      end
      
      function setTEnd(testCase)
         s = testCase.s;
         tEnd = 1;
         s.tEnd = tEnd;

         times = tvec(0,s.dt,size(testCase.values,1));
         ind = times<=tEnd;
         
         testCase.assertEqual(s.times_,{times(ind)},testCase.tolType,testCase.tol);
         testCase.assertEqual(s.values_,{testCase.values(ind)},testCase.tolType,testCase.tol);
         testCase.assertEqual(s.tEnd,tEnd);
      end
      
      function setTStartMultivariate(testCase)
         s = SampledProcess('values',[testCase.values 2*testCase.values],'Fs',testCase.Fs);         
         tEnd = 1;
         s.tEnd = tEnd;

         times = tvec(0,s.dt,size(testCase.values,1));
         ind = times<=tEnd;
         
         testCase.assertEqual(s.times_,{times(ind)},testCase.tolType,testCase.tol);
         testCase.assertEqual(s.values_,{[testCase.values(ind) 2*testCase.values(ind)]},testCase.tolType,testCase.tol);
         testCase.assertEqual(s.tEnd,tEnd);
      end
   end
   
end

