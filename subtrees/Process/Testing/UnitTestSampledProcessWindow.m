% What if window is smaller than DT??? should error
classdef UnitTestSampledProcessWindow < matlab.unittest.TestCase
   %UNTITLED2 Summary of this class goes here
   %   Detailed explanation goes here
   
   properties
      sampledProcess
   end
   
   properties (TestParameter)
      Fs = {1 200.2 2048}
   end
      
   methods (Test)
      function setterSingleValidWindow(testCase,Fs)
         values = (0:2*Fs)'; % times will range from 0 to 2 seconds
         win = [1 1.5];
         dt = 1/Fs;

         s = SampledProcess('values',values,'Fs',Fs);
         s.window = win;
         
         times = SampledProcess.tvec(0,dt,size(values,1));
         ind = (times>=win(1)) & (times<=win(2));

         testCase.assertEqual(numel(s.times),1);
         testCase.assertEqual(s.times{1},times(ind),'AbsTol',eps);
         testCase.assertEqual(numel(s.values),1);
         testCase.assertEqual(s.values{1},values(ind));
         testCase.assertTrue(s.isValidWindow);
      end

      function setrSingleValidWindow(testCase,Fs)
         values = (0:2*Fs)'; % times will range from 0 to 2 seconds
         win = [1 1.5];
         dt = 1/Fs;

         s = SampledProcess('values',values,'Fs',Fs);
         set(s,'window',win);
         
         times = SampledProcess.tvec(0,dt,size(values,1));
         ind = (times>=win(1)) & (times<=win(2));

         testCase.assertEqual(numel(s.times),1);
         testCase.assertEqual(s.times{1},times(ind),'AbsTol',eps);
         testCase.assertEqual(numel(s.values),1);
         testCase.assertEqual(s.values{1},values(ind));
         testCase.assertTrue(s.isValidWindow);
      end
      
      function setterSingleInvalidWindow(testCase,Fs)
         values = (0:2*Fs)'; % times will range from 0 to 2 seconds
         win = [-1 3];
         dt = 1/Fs;

         s = SampledProcess('values',values,'Fs',Fs);
         s.window = win;
         
         times = SampledProcess.tvec(0,dt,size(values,1));
         ind = (times>=win(1)) & (times<=win(2));
         
         % Expected NaN-padding
         [pre,preV] = SampledProcess.extendPre(s.tStart,win(1),dt,1);
         [post,postV] = SampledProcess.extendPost(s.tEnd,win(2),dt,1);
         times = [pre ; times(ind) ; post];
         values = [preV ; values(ind) ; postV];

         testCase.assertEqual(numel(s.times),1);
         testCase.assertEqual(s.times{1},times,'AbsTol',eps);
         testCase.assertEqual(numel(s.values),1);
         testCase.assertEqual(s.values{1},values);
         testCase.assertFalse(s.isValidWindow);
      end

      function setSingleInvalidWindow(testCase,Fs)
         values = (0:2*Fs)'; % times will range from 0 to 2 seconds
         win = [-1 3];
         dt = 1/Fs;

         s = SampledProcess('values',values,'Fs',Fs);
         set(s,'window',win);
         
         times = SampledProcess.tvec(0,dt,size(values,1));
         ind = (times>=win(1)) & (times<=win(2));
         
         % Expected NaN-padding
         [pre,preV] = SampledProcess.extendPre(s.tStart,win(1),dt,1);
         [post,postV] = SampledProcess.extendPost(s.tEnd,win(2),dt,1);
         times = [pre ; times(ind) ; post];
         values = [preV ; values(ind) ; postV];

         testCase.assertEqual(numel(s.times),1);
         testCase.assertEqual(s.times{1},times,'AbsTol',eps);
         testCase.assertEqual(numel(s.values),1);
         testCase.assertEqual(s.values{1},values);
         testCase.assertFalse(s.isValidWindow);
      end
      
      % rewindow single
      % rewindow multi (matching nwin)
      % rewindow multi (non-matching nwin)
   end
   
end

