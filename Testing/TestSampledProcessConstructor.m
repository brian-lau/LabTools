classdef TestSampledProcessConstructor < matlab.unittest.TestCase
   %UNTITLED2 Summary of this class goes here
   %   Detailed explanation goes here
   
   methods (Test)
      function testNoArgs(testCase)
         s = SampledProcess();
         testCase.assertClass(s,'SampledProcess');
      end
      
      function singleInput(testCase)
         s = SampledProcess((1:5)');
         testCase.assertEqual(s.times{1},(0:4)');
         testCase.assertEqual(s.values{1},(1:5)');
         
         testCase.assertEqual(s.tStart,0);
         testCase.assertEqual(s.tEnd,4);
         testCase.assertTrue(s.isValidWindow);
         testCase.assertEqual(s.window_,[0 4]);
         testCase.assertEqual(s.offset_,0);
      end
      
      
   end
end

