% should setting tStart/tEnd trigger reload from values_, or
% setInclusiveWindow?
classdef TestSampledProcessTStart < matlab.unittest.TestCase
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
         tStart = [1 2];

         testCase.assertError(@() set(s,'tStart',tStart),'SampledProcess:tStart:InputFormat');
      end
      
      function errorLessThanTEnd(testCase)
         s = testCase.s;
         tStart = 3;

         testCase.assertError(@() set(s,'tStart',tStart),'SampledProcess:tStart:InputValue');
      end
      
      function setTStart(testCase)
         s = testCase.s;
         tStart = 1;
         s.tStart = tStart;

         times = SampledProcess.tvec(0,s.dt,size(testCase.values,1));
         ind = times>=tStart;
         
         testCase.assertEqual(s.times_,{times(ind)},testCase.tolType,testCase.tol);
         testCase.assertEqual(s.values_,{testCase.values(ind)},testCase.tolType,testCase.tol);
         testCase.assertEqual(s.tStart,tStart);
      end
   end
   
end

