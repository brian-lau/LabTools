classdef TestPointProcessOffset < matlab.unittest.TestCase
   properties
      tolType = 'AbsTol'
      tol = eps;
      p
      times
      values
   end
   
   methods(TestMethodSetup)
      function setup(testCase)
         testCase.times = (1:10)';
         testCasevalues = (1:10)';
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
      function errorNumOffsets(testCase)
         p = testCase.p;
         offset = [1.5 2.5];

         testCase.assertError(@() set(p,'offset',offset),'Process:checkOffset:InputFormat');
      end
      
      function setterOffset(testCase)
         p = testCase.p;
         offset = 1.5;
         p.offset = offset;
                  
         times = offset + testCase.times;
         
         testCase.assertEqual(p.offset,offset);
         testCase.assertEqual(p.times,{times},testCase.tolType,testCase.tol);
      end
      
      function setOffset(testCase)
         p = testCase.p;
         offset = 1.5;
         set(p,'offset',offset);
                  
         times = offset + testCase.times;
         
         testCase.assertEqual(p.offset,offset);
         testCase.assertEqual(p.times,{times},testCase.tolType,testCase.tol);
      end
      
      function setOffsetMultiWinWithSame(testCase)
         p = testCase.p;
         p.window = [0 1; 1 2];
         offset = 1.5;
         p.offset = offset;

         testCase.assertEqual(p.offset,repmat(offset,size(p.window,1),1));
      end
      
      function setOffsetMultiWinWithDiff(testCase)
         p = testCase.p;
         p.window = [0 1; 1 2];
         offset = [1.5 2.5]';
         p.offset = offset;

         testCase.assertEqual(p.offset,offset);
      end
      
      function setOffsetArrayWithSame(testCase)
         p = testCase.p;
         p(2) = PointProcess('times',testCase.times,'values',testCase.values);
         offset = 1.5;
         setOffset(p,offset);
         
         testCase.assertEqual(p(1).offset,offset);
         testCase.assertEqual(p(2).offset,offset);
      end

      function setOffsetArrayWithDiff(testCase)
         p = testCase.p;
         p(2) = PointProcess('times',testCase.times,'values',testCase.values);
         offset = [1.5 2.5];
         setOffset(p,offset);
         
         testCase.assertEqual(p(1).offset,offset(1));
         testCase.assertEqual(p(2).offset,offset(2));
      end
      
      function cumulOffset(testCase)
         p = testCase.p;
         offset1 = 1.5;
         offset2 = -2.5;
         
         testCase.assertEqual(p.cumulOffset,0);
         
         p.offset = offset1;

         testCase.assertEqual(p.cumulOffset,offset1);
         
         p.offset = offset2;
         times = offset1 + offset2 + testCase.times;

         testCase.assertEqual(p.cumulOffset,offset1 + offset2);
         testCase.assertEqual(p.times,{times},testCase.tolType,testCase.tol);
      end

      function cumulOffsetAfterWindow(testCase)
         p = testCase.p;
         offset1 = 1.5;
         offset2 = -2.5;
         win = [1 5]; % in original times
         
         p.offset = offset1;
         p.offset = offset2;
         p.window = win;
         
         times = testCase.times;
         % Window applies to original times
         ind = (times>=win(1)) & (times<=win(2));
         times = offset1 + offset2 + times(ind);

         testCase.assertEqual(p.offset,offset2);
         testCase.assertEqual(p.cumulOffset,offset1 + offset2);
         testCase.assertEqual(p.times,{times},testCase.tolType,testCase.tol);
      end
   end
   
end

