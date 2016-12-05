classdef TestSpectralProcessMean < matlab.unittest.TestCase
   properties
      tolType = 'AbsTol'
      tol = eps;
      s
      values
   end
   
   methods(TestMethodSetup)
      function setup(testCase)
         v = ones(15,10);
         testCase.values = cat(3,v,2*v,3*v);
         testCase.s = SpectralProcess('values',testCase.values,'tStep',.25,'tBlock',.5,'f',1:10);
         l = testCase.s.labels;
         testCase.s(2) = SpectralProcess('values',testCase.values,'tStep',.25,'tBlock',.5,'f',1:10,'labels',l);
      end
   end
   
   methods(TestMethodTeardown)
      function teardown(testCase)
         testCase.s = [];
         testCase.values = [];
      end
   end
   
   methods (Test)
      function nanmean(testCase)
         s = testCase.s;
         % Window twice to introduce NaNs
         win = s(2).window;
         s(2).window = [0 2];
         s(2).window = s(1).window;

         [m,n,count] = s.mean();
         
         values = nanmean(cat(4,s(1).values{1},s(2).values{1}),4);
         nonnans = ~isnan(s(1).values{1}) + ~isnan(s(2).values{1});
         
         testCase.assertEqual(m.Fs,s(1).Fs);
         testCase.assertEqual(m.window,s(1).relWindow);
         testCase.assertEqual(m.tStart,s(1).relWindow(1));
         testCase.assertEqual(m.tEnd,s(1).relWindow(2));
         testCase.assertEqual(m.labels,s(1).labels);
         testCase.assertEqual(m.times,s(1).times,testCase.tolType,testCase.tol);
         testCase.assertEqual(m.values,{values},testCase.tolType,testCase.tol);
         testCase.assertEqual(n,[2 2 2],testCase.tolType,testCase.tol);
         testCase.assertEqual(count,nonnans,testCase.tolType,testCase.tol);
      end
      
      function mean(testCase)
         s = testCase.s;
         % Window twice to introduce NaNs
         win = s(2).window;
         s(2).window = [0 2];
         s(2).window = s(1).window;

         [m,n,count] = s.mean('method','mean');
         
         values = mean(cat(4,s(1).values{1},s(2).values{1}),4);
         nonnans = ~isnan(s(1).values{1}) + ~isnan(s(2).values{1});
         
         testCase.assertEqual(m.values,{values},testCase.tolType,testCase.tol);
         testCase.assertEqual(n,[2 2 2],testCase.tolType,testCase.tol);
         testCase.assertEqual(count,nonnans,testCase.tolType,testCase.tol);
      end
      
      function trimmean(testCase)
         s = testCase.s;
         l = s(1).labels;
         for i = 1:20
            s(2+i) = SpectralProcess('values',testCase.values,'tStep',.25,'tBlock',.5,'f',1:10,'labels',l);
         end
         s.map(@(x) x*0 + trnd(1,size(x)));

         m = s.mean('method','trimmean','percent',10);

         values = [];
         for i = 1:numel(s)
            values = cat(4,values,s(i).values{1});
         end
         values = trimmean(values,10,'round',4);
         
         testCase.assertEqual(m.values,{values},testCase.tolType,testCase.tol);
      end

      function subset(testCase)
         s = testCase.s;

         s(3) = SpectralProcess('values',testCase.values,'tStep',.25,'tBlock',.5,'f',1:10);
         [m,n] = s.mean('label',s(1).labels(2));
         
         values = nanmean(cat(4,s(1).values{1}(:,:,2),s(2).values{1}(:,:,2)),4);
         
         testCase.assertEqual(m.values,{values},testCase.tolType,testCase.tol);
         testCase.assertEqual(n,2,testCase.tolType,testCase.tol);
      end
      
      function empty(testCase)
         s = testCase.s;

         [m,n] = s.mean('label',metadata.Label);
         
         testCase.assertTrue(isempty(m.values{1}));
         testCase.assertTrue(isempty(m.times{1}));
         testCase.assertTrue(isempty(m.labels));
         testCase.assertTrue(isempty(n));
      end      
   end
   
end

