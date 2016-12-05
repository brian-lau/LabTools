classdef TestSpectralProcessNormalize < matlab.unittest.TestCase
   properties
      tolType = 'AbsTol'
      tol = 1e-14;
      Fs = 40
      s
      normWin = [1 2.5];
      values
   end
   
   methods(TestMethodSetup)
      function setup(testCase)
         rng(1234);
         v = randn(101,10);
         testCase.values{1} = cat(3,1 + v,2 + 2*v,3 + 3*v);
         
         testCase.s = SpectralProcess('values',testCase.values{1},'f',1:10,'tStep',1/testCase.Fs,'tBlock',.5);
         l = testCase.s.labels;
         for i = 2:3
            v = randn(101,10);
            testCase.values{i} = cat(3,1 + v,2 + 2*v,3 + 3*v);
            testCase.s(i) = SpectralProcess('values',testCase.values{i},'labels',l,...
               'f',1:10,'tStep',1/testCase.Fs,'tBlock',.5);
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
         s(1) = SampledProcess(randn(500,1),'Fs',1000);
         s(2) = SampledProcess(randn(500,1),'Fs',1000);
         
         tStep = 0.25;
         tf = tfr(s,'method','stft','f',0:100,'tBlock',0.5,'tStep',tStep);
         
         testCase.assertError(@() tf.normalize(0,'window',[0 tStep/2],'method','subtract'),...
            'SpectralProcess:normalize:window:InputValue');
      end
      
      function subtract(testCase)
         s = testCase.s;

         win = testCase.normWin;
         s.normalize(0,'window',win,'method','s');

         n = size(testCase.values{1},1);
         t = tvec(0,1/testCase.Fs,n);
         ind = (t>=win(1)) & (t<=(win(2)-s(1).tBlock));
    
         m = cellfun(@(x) nanmean(x(ind,:,:)),testCase.values,'uni',0);
         values = cellfun(@(x,y) bsxfun(@minus,x,y),testCase.values,m,'uni',0);
         
         testCase.assertEqual([s.values],values,testCase.tolType,testCase.tol);
      end
      
      function subtractavg(testCase)
         s = testCase.s;

         win = testCase.normWin;
         s.normalize(0,'window',win,'method','s-avg');
         
         n = size(testCase.values{1},1);
         t = tvec(0,1/testCase.Fs,n);
         ind = (t>=win(1)) & (t<=(win(2)-s(1).tBlock));
    
         m = cellfun(@(x) nanmean(x(ind,:,:)),testCase.values,'uni',0);
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
         ind = (t>=win(1)) & (t<=(win(2)-s(1).tBlock));
    
         m = cellfun(@(x) nanmean(x(ind,:,:)),testCase.values,'uni',0);
         sd = cellfun(@(x) nanstd(x(ind,:,:)),testCase.values,'uni',0);
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
         ind = (t>=win(1)) & (t<=(win(2)-s(1).tBlock));
    
         m = cellfun(@(x) nanmean(x(ind,:,:)),testCase.values,'uni',0);
         m = nanmean(cat(1,m{:}));
         temp = cellfun(@(x) x(ind,:,:),testCase.values,'uni',0);
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
         ind = (t>=win(1)) & (t<=(win(2)-s(1).tBlock));
    
         m = cellfun(@(x) nanmean(x(ind,:,:)),testCase.values,'uni',0);
         values = cellfun(@(x,y) bsxfun(@rdivide,x,y),testCase.values,m,'uni',0);
         
         testCase.assertEqual([s.values],values,testCase.tolType,testCase.tol);
      end
      
       function divideavg(testCase)
         s = testCase.s;

         win = testCase.normWin;
         s.normalize(0,'window',win,'method','d-avg');
         
         n = size(testCase.values{1},1);
         t = tvec(0,1/testCase.Fs,n);
         ind = (t>=win(1)) & (t<=(win(2)-s(1).tBlock));
    
         m = cellfun(@(x) nanmean(x(ind,:,:)),testCase.values,'uni',0);
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
         ind = (t>=win(1)) & (t<=(win(2)-s(1).tBlock));
    
         m = cellfun(@(x) nanmean(x(ind,:,:)),testCase.values,'uni',0);
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
         ind = (t>=win(1)) & (t<=(win(2)-s(1).tBlock));
    
         m = cellfun(@(x) nanmean(x(ind,:,:)),testCase.values,'uni',0);
         m = nanmean(cat(1,m{:}));
         temp = cellfun(@(x) bsxfun(@minus,x,m),testCase.values,'uni',0);
         values = cellfun(@(x) 100*bsxfun(@rdivide,x,m),temp,'uni',0);
                  
         testCase.assertEqual([s.values],values,testCase.tolType,100*testCase.tol);
       end
   end
   
end

