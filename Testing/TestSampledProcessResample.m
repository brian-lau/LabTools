classdef TestSampledProcessResample < matlab.unittest.TestCase
   properties
      tolType = 'AbsTol'
      tol = eps;
      Fs = 1000
      Fs2 = 512
      s
      values
      t
   end
   
   methods(TestMethodSetup)
      function setup(testCase)
         dt = 1/testCase.Fs;
         testCase.t = (0:dt:1)'; % times range from 0 to 1 second
         testCase.values = repmat(cos(100*2*pi*testCase.t),1,2);
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
      % resampling through resample() method
      function errorResampleNonpositiveFs(testCase)
         s = testCase.s;
         newFs = 0;

         testCase.assertError(@() resample(s,newFs),'SampledProcess:resample:InputValue');
         testCase.assertEqual(s.Fs,testCase.Fs);
      end
      
      function errorResampleNonscalarFs(testCase)
         s = testCase.s;
         newFs = [0 1];

         testCase.assertError(@() resample(s,newFs),'SampledProcess:resample:InputValue');
         testCase.assertEqual(s.Fs,testCase.Fs);
      end
      
      function errorResampleNonnumericFs(testCase)
         s = testCase.s;
         newFs = true;

         testCase.assertError(@() resample(s,newFs),'SampledProcess:resample:InputValue');
         testCase.assertEqual(s.Fs,testCase.Fs);
      end
      
      % resampling by setting Fs
      function errorSetNonpositiveFs(testCase)
         s = testCase.s;
         newFs = 0;

         testCase.assertError(@() set(s,'Fs',newFs),'SampledProcess:Fs:InputValue');
         testCase.assertEqual(s.Fs,testCase.Fs);
      end
      
      function errorSetNonscalarFs(testCase)
         s = testCase.s;
         newFs = [0 1];

         testCase.assertError(@() set(s,'Fs',newFs),'SampledProcess:Fs:InputValue');
         testCase.assertEqual(s.Fs,testCase.Fs);
      end
      
      function errorSetNonnumericFs(testCase)
         s = testCase.s;
         newFs = true;

         testCase.assertError(@() set(s,'Fs',newFs),'SampledProcess:Fs:InputValue');
         testCase.assertEqual(s.Fs,testCase.Fs);
      end
      
      function resampleFs(testCase)
         s = testCase.s;
         newFs = testCase.Fs2;

         resample(s,newFs);
         [t,z] = testCase.resample(testCase.t,testCase.values,testCase.Fs,newFs);
         
         testCase.assertEqual(s.Fs,testCase.Fs2);
         testCase.assertEqual(s.times,{t},testCase.tolType,testCase.tol);
         testCase.assertEqual(s.values,{z},testCase.tolType,testCase.tol);
      end
      
      function setFs(testCase)
         s = testCase.s;
         newFs = testCase.Fs2;

         s.Fs = newFs;
         [t,z] = testCase.resample(testCase.t,testCase.values,testCase.Fs,newFs);
         
         testCase.assertEqual(s.Fs,testCase.Fs2);
         testCase.assertEqual(s.times,{t},testCase.tolType,testCase.tol);
         testCase.assertEqual(s.values,{z},testCase.tolType,testCase.tol);
      end
      
      % array
      function resampleSameFsArray(testCase)
         s = testCase.s;
         s(2) = SampledProcess('values',testCase.values,'Fs',testCase.Fs);
         newFs = testCase.Fs2;

         resample(s,newFs);
         [t,z] = testCase.resample(testCase.t,testCase.values,testCase.Fs,newFs);
         
         testCase.assertEqual(s(1).Fs,testCase.Fs2);
         testCase.assertEqual(s(1).times,{t},testCase.tolType,testCase.tol);
         testCase.assertEqual(s(1).values,{z},testCase.tolType,testCase.tol);
         testCase.assertEqual(s(2).Fs,testCase.Fs2);
         testCase.assertEqual(s(2).times,{t},testCase.tolType,testCase.tol);
         testCase.assertEqual(s(2).values,{z},testCase.tolType,testCase.tol);
      end
      
      function setSameFsArray(testCase)
         s = testCase.s;
         s(2) = SampledProcess('values',testCase.values,'Fs',testCase.Fs);
         newFs = testCase.Fs2;

         set(s,'Fs',newFs);
         [t,z] = testCase.resample(testCase.t,testCase.values,testCase.Fs,newFs);
         
         testCase.assertEqual(s(1).Fs,testCase.Fs2);
         testCase.assertEqual(s(1).times,{t},testCase.tolType,testCase.tol);
         testCase.assertEqual(s(1).values,{z},testCase.tolType,testCase.tol);
         testCase.assertEqual(s(2).Fs,testCase.Fs2);
         testCase.assertEqual(s(2).times,{t},testCase.tolType,testCase.tol);
         testCase.assertEqual(s(2).values,{z},testCase.tolType,testCase.tol);
      end
      
      % array different Fs? 
   end
   
   methods(Static)
      function [t,z] = resample(t,y,Fs,newFs)
         % Directly call resample from Signal Processing
         [p,q] = rat(newFs/Fs);
         z = resample(y,p,q);
         t = tvec(t(1),1/newFs,size(z,1));
      end
   end
   
end

