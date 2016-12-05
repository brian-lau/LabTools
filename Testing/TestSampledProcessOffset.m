classdef TestSampledProcessOffset < matlab.unittest.TestCase
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
      function errorNumOffsets(testCase)
         s = testCase.s;
         offset = [1.5 2.5];

         testCase.assertError(@() set(s,'offset',offset),'Process:checkOffset:InputFormat');
      end
      
      function setterOffset(testCase)
         s = testCase.s;
         offset = 1.5;
         s.offset = offset;
                  
         times = offset + tvec(0,s.dt,size(testCase.values,1));
         
         testCase.assertEqual(s.offset,offset);
         testCase.assertEqual(s.times,{times},testCase.tolType,testCase.tol);
      end
      
      function setOffset(testCase)
         s = testCase.s;
         offset = 1.5;
         set(s,'offset',offset);
                  
         times = offset + tvec(0,s.dt,size(testCase.values,1));
         
         testCase.assertEqual(s.offset,offset);
         testCase.assertEqual(s.times,{times},testCase.tolType,testCase.tol);
      end
      
      function setOffsetMultiWinWithSame(testCase)
         s = testCase.s;
         s.window = [0 1; 1 2];
         offset = 1.5;
         s.offset = offset;

         testCase.assertEqual(s.offset,repmat(offset,size(s.window,1),1));
      end
      
      function setOffsetMultiWinWithDiff(testCase)
         s = testCase.s;
         s.window = [0 1; 1 2];
         offset = [1.5 2.5]';
         s.offset = offset;

         testCase.assertEqual(s.offset,offset);
      end
      
      function setOffsetArrayWithSame(testCase)
         s = testCase.s;
         s(2) = SampledProcess('values',testCase.values,'Fs',testCase.Fs);
         offset = 1.5;
         setOffset(s,offset);
         
         testCase.assertEqual(s(1).offset,offset);
         testCase.assertEqual(s(2).offset,offset);
      end

      function setOffsetArrayWithDiff(testCase)
         s = testCase.s;
         s(2) = SampledProcess('values',testCase.values,'Fs',testCase.Fs);
         offset = [1.5 2.5];
         setOffset(s,offset);
         
         testCase.assertEqual(s(1).offset,offset(1));
         testCase.assertEqual(s(2).offset,offset(2));
      end
      
      function cumulOffset(testCase)
         s = testCase.s;
         offset1 = 1.5;
         offset2 = -2.5;
         
         testCase.assertEqual(s.cumulOffset,0);
         
         s.offset = offset1;

         testCase.assertEqual(s.cumulOffset,offset1);
         
         s.offset = offset2;
         times = offset1 + offset2 + tvec(0,s.dt,size(testCase.values,1));

         testCase.assertEqual(s.cumulOffset,offset1 + offset2);
         testCase.assertEqual(s.times,{times},testCase.tolType,testCase.tol);
      end

      function cumulOffsetAfterWindow(testCase)
         s = testCase.s;
         offset1 = 1.5;
         offset2 = -2.5;
         win = [1 2]; % in original times
         
         s.offset = offset1;
         s.offset = offset2;
         s.window = win;
         
         times = tvec(0,s.dt,size(testCase.values,1));
         % Window applies to original times
         ind = (times>=win(1)) & (times<=win(2));
         times = offset1 + offset2 + times(ind);

         testCase.assertEqual(s.offset,offset2);
         testCase.assertEqual(s.cumulOffset,offset1 + offset2);
         testCase.assertEqual(s.times,{times},testCase.tolType,testCase.tol);
      end
   end
   
end

