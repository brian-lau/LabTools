% should setting tEnd/tEnd trigger reload from values_, or
% setInclusiveWindow?
classdef TestPointProcessTEnd < matlab.unittest.TestCase
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
         tEnd = [1 2];

         testCase.assertError(@() set(obj,'tEnd',tEnd),'PointProcess:tEnd:InputFormat');
      end
      
      function errorLessThanTStart(testCase)
         obj = testCase.obj;
         tEnd = 0;

         testCase.assertError(@() set(obj,'tEnd',tEnd),'PointProcess:tEnd:InputValue');
      end
      
      function setTEnd(testCase)
         obj = testCase.obj;
         tEnd = 1;
         obj.tEnd = tEnd;

         times = testCase.times;
         ind = times<=tEnd;
         
         testCase.assertEqual(obj.times_,{times(ind)},testCase.tolType,testCase.tol);
         testCase.assertEqual(obj.values_,{testCase.values(ind)},testCase.tolType,testCase.tol);
         testCase.assertEqual(obj.tEnd,tEnd);
      end
      
      function setTStartMultivariate(testCase)
         obj = PointProcess('times',repmat({testCase.times},1,3),...
            'values',{testCase.values 2*testCase.values 3*testCase.values});
         
         tEnd = 1;
         obj.tEnd = tEnd;

         times = testCase.times;
         ind = times<=tEnd;
         
         testCase.assertEqual(obj.times_,repmat({times(ind)},1,3),testCase.tolType,testCase.tol);
         testCase.assertEqual(obj.values_,{testCase.values(ind) 2*testCase.values(ind) 3*testCase.values(ind)},...
            testCase.tolType,testCase.tol);
         testCase.assertEqual(obj.tEnd,tEnd);
      end
   end
   
end

