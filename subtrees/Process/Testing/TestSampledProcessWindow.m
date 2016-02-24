% What if window is smaller than DT??? should error
classdef TestSampledProcessWindow < matlab.unittest.TestCase
   properties
      tolType = 'AbsTol'
      tol = eps;
   end
   
   properties (TestParameter)
      Fs = {1 2048.1} % test at different sampling frequencies
   end
   
   methods (Test)
      function errorFormatScalar(testCase,Fs)
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         s = SampledProcess('values',values,'Fs',Fs);
         win = 1;

         testCase.assertError(@() set(s,'window',win),'Process:checkWindow:InputFormat');
      end
      
      function errorFormatVector(testCase,Fs)
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         s = SampledProcess('values',values,'Fs',Fs);
         win = [1 2]';

         testCase.assertError(@() set(s,'window',win),'Process:checkWindow:InputFormat');
      end
      
      function errorAscending(testCase,Fs)
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         s = SampledProcess('values',values,'Fs',Fs);
         win = [1 -1.5];

         testCase.assertError(@() set(s,'window',win),'Process:checkWindow:InputValue');
      end
      
      function setterSingleValidWindow(testCase,Fs)
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         win = [1 1.5];
         dt = 1/Fs;
         
         s = SampledProcess('values',values,'Fs',Fs);
         s.window = win;
         
         times = tvec(0,dt,size(values,1));
         ind = (times>=win(1)) & (times<=win(2));
         
         testCase.assertEqual(s.times,{times(ind)},testCase.tolType,testCase.tol);
         testCase.assertEqual(s.values,{values(ind)});
      end
      
      function setSingleValidWindow(testCase,Fs)
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         win = [1 1.5];
         dt = 1/Fs;
         
         s = SampledProcess('values',values,'Fs',Fs);
         set(s,'window',win);
         
         times = tvec(0,dt,size(values,1));
         ind = (times>=win(1)) & (times<=win(2));
         
         testCase.assertEqual(s.times,{times(ind)},testCase.tolType,testCase.tol);
         testCase.assertEqual(s.values,{values(ind)});
      end
      
      function setterSingleInvalidWindow(testCase,Fs)
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         win = [-1 3];
         dt = 1/Fs;
         
         s = SampledProcess('values',values,'Fs',Fs);
         s.window = win;
         
         times = tvec(0,dt,size(values,1));
         ind = (times>=win(1)) & (times<=win(2));
         
         % Expected NaN-padding
         [pre,preV] = extendPre(s.tStart,win(1),dt,1);
         [post,postV] = extendPost(s.tEnd,win(2),dt,1);
         times = [pre ; times(ind) ; post];
         values = [preV ; values(ind) ; postV];
         
         testCase.assertEqual(s.times,{times},testCase.tolType,testCase.tol);
         testCase.assertEqual(s.values,{values});
      end
      
      function setSingleInvalidWindow(testCase,Fs)
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         win = [-1 3];
         dt = 1/Fs;
         
         s = SampledProcess('values',values,'Fs',Fs);
         set(s,'window',win);
         
         times = tvec(0,dt,size(values,1));
         ind = (times>=win(1)) & (times<=win(2));
         
         % Expected NaN-padding
         [pre,preV] = extendPre(s.tStart,win(1),dt,1);
         [post,postV] = extendPost(s.tEnd,win(2),dt,1);
         times = [pre ; times(ind) ; post];
         values = [preV ; values(ind) ; postV];
         
         testCase.assertEqual(s.times,{times},testCase.tolType,testCase.tol);
         testCase.assertEqual(s.values,{values});
      end
      
      function setterMultiValidWindow(testCase,Fs)
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         win = [0 1 ; 1 2 ; 0 2];
         nWin = size(win,1);
         dt = 1/Fs;
         
         s = SampledProcess('values',values,'Fs',Fs);
         s.window = win;
         
         times = tvec(0,dt,size(values,1));
         for i = 1:nWin
            ind = (times>=win(i,1)) & (times<=win(i,2));
            T{i,1} = times(ind);
            V{i,1} = values(ind);
         end
         
         testCase.assertEqual(s.times,T,testCase.tolType,testCase.tol);
         testCase.assertEqual(s.values,V);
      end
      
      function setterMultiInvalidWindow(testCase,Fs)
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         win = [-1 1 ; 1 3 ; -1 3];
         nWin = size(win,1);
         dt = 1/Fs;
         
         s = SampledProcess('values',values,'Fs',Fs);
         s.window = win;
         
         times = tvec(0,dt,size(values,1));
         for i = 1:nWin
            ind = (times>=win(i,1)) & (times<=win(i,2));
            
            % Expected NaN-padding
            [pre,preV] = extendPre(s.tStart,win(i,1),dt,1);
            [post,postV] = extendPost(s.tEnd,win(i,2),dt,1);
            
            T{i,1} = [pre ; times(ind) ; post];
            V{i,1} = [preV ; values(ind) ; postV];
         end
         
         testCase.assertEqual(s.times,T,testCase.tolType,testCase.tol);
         testCase.assertEqual(s.values,V);
      end
      
      function rewindowSingleValidWindow(testCase,Fs)
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         win = [1 1.5];
         dt = 1/Fs;
         
         s = SampledProcess('values',values,'Fs',Fs);
         s.window = win;
         win2 = [0 2];
         s.window = win2;
         
         times = tvec(0,dt,size(values,1));
         ind = (times>=win2(1)) & (times<=win2(2));
         
         % Times outside the previous window are expected to map to NaN
         ind2 = (times<win(1)) | (times>win(2));
         values(ind2) = NaN;
         values = values(ind);
         
         testCase.assertEqual(s.times,{times(ind)},testCase.tolType,testCase.tol);
         testCase.assertEqual(s.values,{values});
      end

%       % rewindow single, initial valid, second invalid
%       function rewindowSingleValidWindowInitialInvalid(testCase,Fs)
%          values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
%          dt = 1/Fs;
%          
%          s = SampledProcess('values',values,'Fs',Fs);
%          
%          win2 = [-2 -1];
%          s.window = win2;
%          
%          times = (win2(1):dt:win2(2))';
%          
%          testCase.assertEqual(s.times,{times},testCase.tolType,testCase.tol);
%          testCase.assertEqual(s.values,{nan(size(s.values{1}))});
%       end
      
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
         
         times = tvec(0,dt,size(values,1));
         for i = 1:nWin
            ind = (times>=win2(i,1)) & (times<=win2(i,2));
            
            % Times outside the previous window are expected to map to NaN
            ind2 = (times<win(i,1)) | (times>win(i,2));
            temp = values;
            temp(ind2) = NaN;
            
            T{i,1} = times(ind);
            V{i,1} = temp(ind);
         end
                 
         testCase.assertEqual(s.times,T,testCase.tolType,testCase.tol);
         testCase.assertEqual(s.values,V);
      end
      
      % Rewindowing with non-matching number of windows will reset the Process
      function rewindowMultiValidNonmatchingWindow(testCase,Fs)
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         win = [0 1 ; 1 2 ; 0 2];
         dt = 1/Fs;
         
         s = SampledProcess('values',values,'Fs',Fs);
         s.window = win;
         s.map(@(x) x + 1); % Change values to ensure reset
         win2 = [1 2 ; 0 1];
         nWin = size(win2,1);
         s.window = win2;
         
         times = tvec(0,dt,size(values,1));
         for i = 1:nWin
            ind = (times>=win2(i,1)) & (times<=win2(i,2));
            
            T{i,1} = times(ind);
            V{i,1} = values(ind);
         end
         
         testCase.assertEqual(s.times,T,testCase.tolType,testCase.tol);
         testCase.assertEqual(s.values,V);
      end
      
      function setWindowWithSameArray(testCase,Fs)
         values1 = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         values2 = 10 + (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         win = [0.5 2.5];
         dt = 1/Fs;
         
         s(1) = SampledProcess('values',values1,'Fs',Fs);
         s(2) = SampledProcess('values',values2,'Fs',Fs);
         setWindow(s,win);
         
         testCase.assertEqual(s(1).window,win);
         testCase.assertEqual(s(2).window,win);
      end
      
      function setWindowWithDiffArray(testCase,Fs)
         values1 = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         values2 = 10 + (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         win1 = [0 1.5];
         win2 = [0.5 2.5];
         dt = 1/Fs;
         
         s(1) = SampledProcess('values',values1,'Fs',Fs);
         s(2) = SampledProcess('values',values2,'Fs',Fs);
         setWindow(s,{win1 ; win2});
         
         testCase.assertEqual(s(1).window,win1);
         testCase.assertEqual(s(2).window,win2);
      end
      
      function setInclusiveWindow(testCase,Fs)
         values = (0:2*ceil(Fs))'; % times range from 0 to at least 2 seconds
         win = [1 1.5];
         dt = 1/Fs;
         
         s = SampledProcess('values',values,'Fs',Fs);
         s.window = win;         
         s.setInclusiveWindow();
         
         testCase.assertEqual(s.window,[s.tStart s.tEnd]);
      end
   end
   
end

