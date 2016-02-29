classdef TestSampledProcessNormalize < matlab.unittest.TestCase
   properties
      tolType = 'AbsTol'
      tol = 1e-14;
      Fs = 1000
      s
      normWin = [0.25 .75];
      values
   end
   
   methods(TestMethodSetup)
      function setup(testCase)
         rng(1234);
         v = randn(1001,1);
         testCase.values{1} = [1 + v,2 + 2*v,3 + 3*v];
         testCase.s = SampledProcess('values',testCase.values{1},'Fs',testCase.Fs);
         l = testCase.s.labels;
         for i = 2:3
            v = randn(1001,1);
            testCase.values{i} = [1 + v,2 + 2*v,3 + 3*v];
            testCase.s(i) = SampledProcess('values',testCase.values{i},'Fs',testCase.Fs,'labels',l);
         end
      end
   end
   
   methods(TestMethodTeardown)
      function teardown(testCase)
         testCase.s = [];
         testCase.values = [];
      end
   end
   
   methods (Test)
      function errorWindowTooSmall(testCase)         
         testCase.assertError(@() testCase.s.normalize(0,'window',[0 (1/testCase.Fs)/2],'method','subtract'),...
            'SampledProcess:normalize:window:InputValue');
      end
      
      function subtract(testCase)
         s = testCase.s;

         win = testCase.normWin;
         s.normalize(0,'window',win,'method','s');
         
         n = size(testCase.values{1},1);
         t = tvec(0,1/testCase.Fs,n);
         ind = (t>=win(1)) & (t<=win(2));
    
         m = cellfun(@(x) nanmean(x(ind,:)),testCase.values,'uni',0);
         values = cellfun(@(x,y) bsxfun(@minus,x,y),testCase.values,m,'uni',0);
         
         testCase.assertEqual([s.values],values,testCase.tolType,testCase.tol);
      end
      
      function subtractavg(testCase)
         s = testCase.s;

         win = testCase.normWin;
         s.normalize(0,'window',win,'method','s-avg');
         
         n = size(testCase.values{1},1);
         t = tvec(0,1/testCase.Fs,n);
         ind = (t>=win(1)) & (t<=win(2));
    
         m = cellfun(@(x) nanmean(x(ind,:)),testCase.values,'uni',0);
         m = nanmean(cat(1,m{:}));
         values = cellfun(@(x) bsxfun(@minus,x,m),testCase.values,'uni',0);
         
         testCase.assertEqual([s.values],values,testCase.tolType,testCase.tol);
      end
      
      function zscore(testCase)
         s = testCase.s;

         win = testCase.normWin;
         s.normalize(0,'window',win,'method','z');
         
         n = size(testCase.values{1},1);
         t = tvec(0,1/testCase.Fs,n);
         ind = (t>=win(1)) & (t<=win(2));
    
         m = cellfun(@(x) nanmean(x(ind,:)),testCase.values,'uni',0);
         sd = cellfun(@(x) nanstd(x(ind,:)),testCase.values,'uni',0);
         temp = cellfun(@(x,y) bsxfun(@minus,x,y),testCase.values,m,'uni',0);
         values = cellfun(@(x,y) bsxfun(@rdivide,x,y),temp,sd,'uni',0);
                  
         testCase.assertEqual([s.values],values,testCase.tolType,testCase.tol);
      end
      
      function zscoreavg(testCase)
         s = testCase.s;

         win = testCase.normWin;
         s.normalize(0,'window',win,'method','z-avg');
         
         n = size(testCase.values{1},1);
         t = tvec(0,1/testCase.Fs,n);
         ind = (t>=win(1)) & (t<=win(2));
    
         m = cellfun(@(x) nanmean(x(ind,:)),testCase.values,'uni',0);
         m = nanmean(cat(1,m{:}));
         temp = cellfun(@(x) x(ind,:),testCase.values,'uni',0);
         sd = nanstd(cat(1,temp{:}));
         temp = cellfun(@(x) bsxfun(@minus,x,m),testCase.values,'uni',0);
         values = cellfun(@(x) bsxfun(@rdivide,x,sd),temp,'uni',0);
                  
         testCase.assertEqual([s.values],values,testCase.tolType,testCase.tol);
      end
      
      function divide(testCase)
         s = testCase.s;

         win = testCase.normWin;
         s.normalize(0,'window',win,'method','d');
         
         n = size(testCase.values{1},1);
         t = tvec(0,1/testCase.Fs,n);
         ind = (t>=win(1)) & (t<=win(2));
    
         m = cellfun(@(x) nanmean(x(ind,:)),testCase.values,'uni',0);
         values = cellfun(@(x,y) bsxfun(@rdivide,x,y),testCase.values,m,'uni',0);
         
         testCase.assertEqual([s.values],values,testCase.tolType,testCase.tol);
      end
      
       function divideavg(testCase)
         s = testCase.s;

         win = testCase.normWin;
         s.normalize(0,'window',win,'method','d-avg');
         
         n = size(testCase.values{1},1);
         t = tvec(0,1/testCase.Fs,n);
         ind = (t>=win(1)) & (t<=win(2));
    
         m = cellfun(@(x) nanmean(x(ind,:)),testCase.values,'uni',0);
         m = nanmean(cat(1,m{:}));
         values = cellfun(@(x) bsxfun(@rdivide,x,m),testCase.values,'uni',0);
                  
         testCase.assertEqual([s.values],values,testCase.tolType,testCase.tol);
       end
       
       function percentage(testCase)
         s = testCase.s;

         win = testCase.normWin;
         s.normalize(0,'window',win,'method','p');
         
         n = size(testCase.values{1},1);
         t = tvec(0,1/testCase.Fs,n);
         ind = (t>=win(1)) & (t<=win(2));
    
         m = cellfun(@(x) nanmean(x(ind,:)),testCase.values,'uni',0);
         temp = cellfun(@(x,y) bsxfun(@minus,x,y),testCase.values,m,'uni',0);
         values = cellfun(@(x,y) 100*bsxfun(@rdivide,x,y),temp,m,'uni',0);
                  
         testCase.assertEqual([s.values],values,testCase.tolType,100*testCase.tol);
       end
      
       function percentageavg(testCase)
         s = testCase.s;

         win = testCase.normWin;
         s.normalize(0,'window',win,'method','p-avg');
         
         n = size(testCase.values{1},1);
         t = tvec(0,1/testCase.Fs,n);
         ind = (t>=win(1)) & (t<=win(2));
    
         m = cellfun(@(x) nanmean(x(ind,:)),testCase.values,'uni',0);
         m = nanmean(cat(1,m{:}));
         temp = cellfun(@(x) bsxfun(@minus,x,m),testCase.values,'uni',0);
         values = cellfun(@(x) 100*bsxfun(@rdivide,x,m),temp,'uni',0);
                  
         testCase.assertEqual([s.values],values,testCase.tolType,100*testCase.tol);
       end
   end
   
end

