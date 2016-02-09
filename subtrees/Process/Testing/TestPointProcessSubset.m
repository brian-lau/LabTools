classdef TestPointProcessSubset < matlab.unittest.TestCase
   properties
      tolType = 'AbsTol'
      tol = eps;
      p
      times
      values
      quality
   end
   
   methods(TestMethodSetup)
      function setup(testCase)
         testCase.times = {(1:10)' (11:20)' (21:30)'};
         testCase.values = {(1:10)' (11:20)' (21:30)'};
         testCase.quality = [1 2 3];
         testCase.p = PointProcess('times',testCase.times,'values',testCase.values,'quality',testCase.quality);
      end
   end
   
   methods(TestMethodTeardown)
      function teardown(testCase)
         testCase.p = [];
         testCase.times = [];
         testCase.values = [];
         testCase.quality = [];
      end
   end
   
   methods (Test)
      function errorNonIntegerIndex(testCase)
         p = testCase.p;

         testCase.assertError(@() p.subset('index',1.1),'Process:subset:InputFormat');
      end
      
      function warningIndexOutOfRange(testCase)
         p = testCase.p;

         testCase.assertWarning(@() p.subset('index',1000),'Process:subset');
      end
      
      function errorBadLogic(testCase)
         p = testCase.p;

         testCase.assertError(@() p.subset('index',1,'logic','x'),'MATLAB:InputParser:ArgumentFailedValidation');
      end
      
      function subsetIndex(testCase)
         p = testCase.p;
         
         ind = [2 3];
         p.subset('index',ind);
         
         testCase.assertEqual(p.times,testCase.times(:,ind));         
         testCase.assertEqual(p.values,testCase.values(:,ind));         
      end
      
      function subsetLabel(testCase)
         p = testCase.p;
         
         ind = [2 3];
         l = p.labels(ind);
         p.subset('label',l);
         
         testCase.assertEqual(p.times,testCase.times(:,ind));         
         testCase.assertEqual(p.values,testCase.values(:,ind));         
      end
      
      function subsetLabelName(testCase)
         p = testCase.p;
         
         l = 'id3';
         p.subset('labelVal',l);
         
         testCase.assertEqual(p.times,testCase.times(:,3));         
         testCase.assertEqual(p.values,testCase.values(:,3));         
      end
      
      function subsetLabelGroupingString(testCase)
         p = testCase.p;
         
         p.labels(1).grouping = 'cat';
         p.labels(3).grouping = 'cat';
         p.subset('labelVal','cat','labelProp','grouping');
         
         testCase.assertEqual(p.times,testCase.times(:,[1 3]));         
         testCase.assertEqual(p.values,testCase.values(:,[1 3]));         
      end
      
      function subsetLabelGroupingNumeric(testCase)
         p = testCase.p;
         
         p.labels(1).grouping = 1;
         p.labels(3).grouping = 1;
         p.subset('labelVal',1,'labelProp','grouping');
         
         testCase.assertEqual(p.times,testCase.times(:,[1 3]));         
         testCase.assertEqual(p.values,testCase.values(:,[1 3]));         
      end
      
      function subsetLabelGroupingHandle(testCase)
         p = testCase.p;
         
         p.labels(1).grouping = metadata.Label('name','hello');
         p.labels(3).grouping = p.labels(1).grouping;
         p.subset('labelVal',p.labels(1).grouping,'labelProp','grouping');
         
         testCase.assertEqual(p.times,testCase.times(:,[1 3]));         
         testCase.assertEqual(p.values,testCase.values(:,[1 3]));         
      end
      
      function subsetQuality(testCase)
         p = testCase.p;
         
         ind = [2 3];
         q = p.quality(ind);
         p.subset('quality',q);
         
         testCase.assertEqual(p.times,testCase.times(:,ind));         
         testCase.assertEqual(p.values,testCase.values(:,ind));         
      end
      
      function subsetLogicOR(testCase)
         p = testCase.p;
         
         l = p.labels(2);
         p.subset('index',1,'label',l,'quality',2);
         
         testCase.assertEqual(p.times,testCase.times(:,1:2));         
         testCase.assertEqual(p.values,testCase.values(:,1:2));         
      end
      
      function subsetLogicAND(testCase)
         p = testCase.p;
         
         l = p.labels(2);
         p.subset('label',l,'quality',2,'logic','and');
         
         testCase.assertEqual(p.times,testCase.times(:,2));         
         testCase.assertEqual(p.values,testCase.values(:,2));         
      end
      
      function subsetLogicXOR(testCase)
         p = testCase.p;
         
         l = p.labels(2);
         p.subset('index',2,'label',l,'quality',2,'logic','xor');
         
         testCase.assertEqual(p.times,testCase.times(:,[1 3]));         
         testCase.assertEqual(p.values,testCase.values(:,[1 3]));         
      end
   end
   
end

