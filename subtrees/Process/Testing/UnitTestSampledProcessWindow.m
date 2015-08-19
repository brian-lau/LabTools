% What if window is smaller than DT??? should error
classdef UnitTestSampledProcessWindow < matlab.unittest.TestCase
   properties
      sampledProcess
   end
   
   properties (TestParameter)
      Fs = {1 200.2 2048} % test at different sampling frequencies
   end
      
   methods (Test)
      function setterSingleValidWindow(testCase,Fs)
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
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

      function setSingleValidWindow(testCase,Fs)
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
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
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
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
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
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
      
      function setterMultiValidWindow(testCase,Fs)
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         win = [0 1 ; 1 2 ; 0 2];
         nWin = size(win,1);
         dt = 1/Fs;

         s = SampledProcess('values',values,'Fs',Fs);
         s.window = win;
         
         times = SampledProcess.tvec(0,dt,size(values,1));
         for i = 1:nWin
            ind = (times>=win(i,1)) & (times<=win(i,2));
            T{i,1} = times(ind);
            V{i,1} = values(ind);
         end

         testCase.assertEqual(numel(s.times),nWin);
         testCase.assertEqual(s.times,T,'AbsTol',eps);
         testCase.assertEqual(numel(s.values),nWin);
         testCase.assertEqual(s.values,V);
         testCase.assertTrue(all(s.isValidWindow));
      end
      
      function setterMultiInvalidWindow(testCase,Fs)
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         win = [-1 1 ; 1 3 ; -1 3];
         nWin = size(win,1);
         dt = 1/Fs;

         s = SampledProcess('values',values,'Fs',Fs);
         s.window = win;
         
         times = SampledProcess.tvec(0,dt,size(values,1));
         for i = 1:nWin
            ind = (times>=win(i,1)) & (times<=win(i,2));
            
            % Expected NaN-padding
            [pre,preV] = SampledProcess.extendPre(s.tStart,win(i,1),dt,1);
            [post,postV] = SampledProcess.extendPost(s.tEnd,win(i,2),dt,1);
            
            T{i,1} = [pre ; times(ind) ; post];
            V{i,1} = [preV ; values(ind) ; postV];
         end

         testCase.assertEqual(numel(s.times),nWin);
         testCase.assertEqual(s.times,T,'AbsTol',eps);
         testCase.assertEqual(numel(s.values),nWin);
         testCase.assertEqual(s.values,V);
         testCase.assertTrue(all(~s.isValidWindow));
      end
      
      function rewindowSingleValidWindow(testCase,Fs)
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         win = [1 1.5];
         dt = 1/Fs;

         s = SampledProcess('values',values,'Fs',Fs);
         s.window = win;
         win2 = [0 2];
         s.window = win2;
         
         times = SampledProcess.tvec(0,dt,size(values,1));
         ind = (times>=win2(1)) & (times<=win2(2));
         
         % Times outside the previous window are expected to map to NaN
         ind2 = (times<win(1)) | (times>win(2));
         values(ind2) = NaN;
         values = values(ind);

         testCase.assertEqual(numel(s.times),1);
         testCase.assertEqual(s.times{1},times(ind),'AbsTol',eps);
         testCase.assertEqual(numel(s.values),1);
         testCase.assertEqual(s.values{1},values);
         testCase.assertTrue(s.isValidWindow);
      end
      
      % rewindow single, initial valid, second invalid
      
      % rewindow multi (matching nwin)
      function rewindowMultiValidWindow(testCase,Fs)
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         win = [0 1 ; 1 2 ; 0 2];
         nWin = size(win,1);
         dt = 1/Fs;

         s = SampledProcess('values',values,'Fs',Fs);
         s.window = win;
         win2 = [1 2 ; 0 1 ; 0 2];
         s.window = win2;
         
         times = SampledProcess.tvec(0,dt,size(values,1));
         for i = 1:nWin
            ind = (times>=win2(i,1)) & (times<=win2(i,2));
            
            % Times outside the previous window are expected to map to NaN
            ind2 = (times<win(i,1)) | (times>win(i,2));
            temp = values;
            temp(ind2) = NaN;
            
            T{i,1} = times(ind);
            V{i,1} = temp(ind);
         end

         testCase.assertEqual(numel(s.times),nWin);
         testCase.assertEqual(s.times,T,'AbsTol',eps);
         testCase.assertEqual(numel(s.values),nWin);
         testCase.assertEqual(s.values,V);
         testCase.assertTrue(all(s.isValidWindow));
      end
      
      % Rewindowing with non-matching number of windows will reset the Process
      function rewindowMultiValidNonmatchingWindow(testCase,Fs)
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         win = [0 1 ; 1 2 ; 0 2];
         dt = 1/Fs;

         s = SampledProcess('values',values,'Fs',Fs);
         s.window = win;
         win2 = [1 2 ; 0 1];
         nWin = size(win2,1);
         s.window = win2;
         
         times = SampledProcess.tvec(0,dt,size(values,1));
         for i = 1:nWin
            ind = (times>=win2(i,1)) & (times<=win2(i,2));
                        
            T{i,1} = times(ind);
            V{i,1} = values(ind);
         end

         testCase.assertEqual(numel(s.times),nWin);
         testCase.assertEqual(s.times,T,'AbsTol',eps);
         testCase.assertEqual(numel(s.values),nWin);
         testCase.assertEqual(s.values,V);
         testCase.assertTrue(all(s.isValidWindow));
      end
   end
   
end

