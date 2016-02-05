classdef TestSpectralProcessNormalize < matlab.unittest.TestCase
   properties
      tolType = 'AbsTol'
      tol = eps;
      
      %tStep
      %tf
   end
   
   methods(TestMethodSetup)
      function setup(testCase)
      end
   end
   
   methods(TestMethodTeardown)
      function teardown(testCase)
         %testCase.tStep = [];
         %testCase.tf = [];
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
      
      function errorLabelMismatch(testCase)
         s(1) = SampledProcess(randn(500,1),'Fs',1000,'labels','a');
         s(2) = SampledProcess(randn(500,1),'Fs',1000,'labels','b');
         
         tStep = 0.25;
         tf = tfr(s,'method','stft','f',0:100,'tBlock',0.5,'tStep',tStep);
         
         testCase.assertError(@() tf.normalize(0,'window',[0 tStep],'method','subtract-avg'),...
            'SpectralProcess:normalize:InputValue');
      end
      
      function errorLabelMismatch2(testCase)
         s(1) = SampledProcess(randn(500,2),'Fs',1000,'labels',{'a' 'b'});
         s(2) = SampledProcess(randn(500,1),'Fs',1000,'labels','b');
         
         tStep = 0.25;
         tf = tfr(s,'method','stft','f',0:100,'tBlock',0.5,'tStep',tStep);
         
         testCase.assertError(@() tf.normalize(0,'window',[0 tStep],'method','subtract-avg'),...
            'MATLAB:catenate:dimensionMismatch');
      end
      
      function errorFrequencyMismatch(testCase)
         s(1) = SampledProcess(randn(500,1),'Fs',1000,'labels','a');
         s(2) = SampledProcess(randn(500,1),'Fs',1000,'labels','b');
         
         tStep = 0.25;
         tf(1) = tfr(s(1),'method','stft','f',0:100,'tBlock',0.5,'tStep',tStep);
         tf(2) = tfr(s(2),'method','stft','f',1:100,'tBlock',0.5,'tStep',tStep);
         
         testCase.assertError(@() tf.normalize(0,'window',[0 tStep],'method','subtract-avg'),...
            'SpectralProcess:normalize:InputValue');
      end
   end
   
end

