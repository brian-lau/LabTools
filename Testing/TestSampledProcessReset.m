classdef TestSampledProcessReset < matlab.unittest.TestCase
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
      function resetDefaultConstructor(testCase)
         s = testCase.s;
         s.window = [0 1];
         s.Fs = testCase.Fs/2;
         reset(s);

         times = tvec(0,s.dt,size(testCase.values,1));
         
         testCase.assertEqual(s.times,{times},testCase.tolType,testCase.tol);
         testCase.assertEqual(s.values,{testCase.values},testCase.tolType,testCase.tol);
         testCase.assertEqual(s.window,[0 max(times)]);
         testCase.assertEqual(s.Fs,testCase.Fs);
         testCase.assertEqual(s.queue,{});
      end
      % Need to deal with undo(), reset() when history is off!
%       function resetDefaultConstructorUndo(testCase)
%          s = testCase.s;
%          win = [0 1];
%          s.window = win;
%          s.Fs = testCase.Fs/2;
%          reset(s,1);
% 
%          times = SampledProcess.tvec(0,s.dt,size(testCase.values,1));
%          ind = (times>=win(1)) & (times<=win(2));
% 
%          testCase.assertEqual(s.times,{times(ind)},testCase.tolType,testCase.tol);
%          testCase.assertEqual(s.values,{testCase.values(ind)},testCase.tolType,testCase.tol);
%          testCase.assertEqual(s.window,win);
%          testCase.assertEqual(s.Fs,testCase.Fs);
%          testCase.assertEqual(s.queue,{});
%       end
   end
   
end

