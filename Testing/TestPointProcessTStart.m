% should setting tStart/tEnd trigger reload from values_, or
% setInclusiveWindow?
classdef TestPointProcessTStart < matlab.unittest.TestCase
   properties
      tolType = 'AbsTol'
      tol = eps;
      obj
      times
      values
   end
   
   methods(TestMethodSetup)
      function setup(testCase)
         testCase.times = (1:10)';
         testCase.values = (1:10)';
         testCase.obj = PointProcess('times',testCase.times,'values',testCase.values);
      end
   end
   
   methods(TestMethodTeardown)
      function teardown(testCase)
         testCase.obj = [];
         testCase.times = [];
         testCase.values = [];
      end
   end
   
   methods (Test)
      function errorNotScalar(testCase)
         obj = testCase.obj;
         tStart = [1 2];

         testCase.assertError(@() set(obj,'tStart',tStart),'PointProcess:tStart:InputFormat');
      end
      
      function errorLessThanTEnd(testCase)
         obj = testCase.obj;
         tStart = 12;

         testCase.assertError(@() set(obj,'tStart',tStart),'PointProcess:tStart:InputValue');
      end
      
      function setTStart(testCase)
         obj = testCase.obj;
         tStart = 1;
         obj.tStart = tStart;

         times = testCase.times;
         ind = times>=tStart;
         
         testCase.assertEqual(obj.times_,{times(ind)},testCase.tolType,testCase.tol);
         testCase.assertEqual(obj.values_,{testCase.values(ind)},testCase.tolType,testCase.tol);
         testCase.assertEqual(obj.tStart,tStart);
      end
      
      function setTStartMultivariate(testCase)
         obj = PointProcess('times',repmat({testCase.times},1,3),...
            'values',{testCase.values 2*testCase.values 3*testCase.values});
         
         tStart = 1;
         obj.tStart = tStart;

         times = testCase.times;
         ind = times>=tStart;
         
         testCase.assertEqual(obj.times_,repmat({times(ind)},1,3),testCase.tolType,testCase.tol);
         testCase.assertEqual(obj.values_,{testCase.values(ind) 2*testCase.values(ind) 3*testCase.values(ind)},...
            testCase.tolType,testCase.tol);
         testCase.assertEqual(obj.tStart,tStart);
      end
   end
   
end

