classdef TestEventProcessChop < matlab.unittest.TestCase
   properties
      tolType = 'AbsTol'
      tol = eps;
      p
      times
      ev
   end
   
   methods(TestMethodSetup)
      function setup(testCase)
         temp = metadata.event.Stimulus();
         for i = 1:10
            temp.tStart = i;
            temp.tEnd = i+0.5;
            temp.name = num2str(i);
            ev1(i) = temp;
         end
         for i = 1:10
            temp.tStart = i+10;
            temp.tEnd = i+10+0.5;
            temp.name = num2str(i);
            ev2(i) = temp;
         end
         testCase.p = EventProcess('events',{ev1 ev2});
         testCase.ev = {ev1' ev2'};
         testCase.times = {(1:10)' (11:20)'};
      end
   end
   
   methods(TestMethodTeardown)
      function teardown(testCase)
         testCase.p = [];
         testCase.times = [];
         testCase.ev = [];
      end
   end
   
   methods (Test)
      function errorNonScalar(testCase)
         p = testCase.p;
         p(2) = EventProcess();

         testCase.assertError(@() chop(p),'Process:chop:InputCount');
      end
      
      function chopShiftToWindow(testCase)
         p = testCase.p;
         p.window = [1 10; 11 20];
         p.chop;
         
         testCase.assertEqual([p.offset],[0 0]);
         testCase.assertEqual([p.cumulOffset],[0 0]);
         times = {[(0:9)',(0:9)'+.5] zeros(0,2)};
         testCase.assertEqual(p(1).times,times,testCase.tolType,testCase.tol);
         times = {zeros(0,2) [(0:9)',(0:9)'+.5]};
         testCase.assertEqual(p(2).times,times,testCase.tolType,testCase.tol);
         
         values = testCase.ev{1};
         temp = num2cell(0:9);
         [values(:).tStart] = temp{:};
         temp = num2cell((0:9)+.5);
         [values(:).tEnd] = temp{:};
         testCase.assertEqual(p(1).values{1},values,testCase.tolType,testCase.tol);
         
         values = testCase.ev{2};
         values(1:9) = [];
         values(1,:) = [];
         testCase.assertEqual(p(1).values{2},values,testCase.tolType,testCase.tol);
         
         values = testCase.ev{2};
         temp = num2cell(0:9);
         [values(:).tStart] = temp{:};
         temp = num2cell((0:9)+.5);
         [values(:).tEnd] = temp{:};
         testCase.assertEqual(p(2).values{2},values,testCase.tolType,testCase.tol);
         
         values = testCase.ev{2};
         values(1:9) = [];
         values(1,:) = [];
         testCase.assertEqual(p(2).values{1},values,testCase.tolType,testCase.tol);
      end

      function chopShiftToWindowFalse(testCase)
         p = testCase.p;
         p.window = [1 10; 11 20];
         p.chop('shiftToWindow',false);
         
         testCase.assertEqual([p.offset],[0 0]);
         testCase.assertEqual([p.cumulOffset],[0 0]);
         
         testCase.assertEqual(p(1).times{1},[(1:10)',.5+(1:10)'],testCase.tolType,testCase.tol);
         testCase.assertEqual(p(1).times{2},zeros(0,2),testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).times{1},zeros(0,2),testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).times{2},[(11:20)',.5+(11:20)'],testCase.tolType,testCase.tol);

         values = testCase.ev{1};
         temp = num2cell(1:10);
         [values(:).tStart] = temp{:};
         temp = num2cell((1:10)+.5);
         [values(:).tEnd] = temp{:};
         testCase.assertEqual(p(1).values{1},values,testCase.tolType,testCase.tol);
         
         values = testCase.ev{2};
         values(1:9) = [];
         values(1,:) = [];
         testCase.assertEqual(p(1).values{2},values,testCase.tolType,testCase.tol);

         values = testCase.ev{2};
         temp = num2cell(11:20);
         [values(:).tStart] = temp{:};
         temp = num2cell((11:20)+.5);
         [values(:).tEnd] = temp{:};
         testCase.assertEqual(p(2).values{2},values,testCase.tolType,testCase.tol);
         
         values = testCase.ev{2};
         values(1:9) = [];
         values(1,:) = [];
         testCase.assertEqual(p(2).values{1},values,testCase.tolType,testCase.tol);
      end

      function chopCopyInfo(testCase)
         p = testCase.p;
         info = p.info;
         p.window = [1 10; 11 20];
         p.chop();
         
         testCase.assertFalse(p(1).info==info);
         testCase.assertFalse(p(2).info==info);
      end
      
      function chopCopyInfoFalse(testCase)
         p = testCase.p;
         info = p.info;
         p.window = [1 10; 11 20];
         p.chop('copyInfo',false);
         
         testCase.assertTrue(p(1).info==info);
         testCase.assertTrue(p(2).info==info);
      end
      
      function chopCopyLabelFalse(testCase)
         p = testCase.p;
         info = p.info;
         p.window = [1 10; 11 20];
         p.chop();
         
         testCase.assertTrue(p(1).labels(1)==p(2).labels(1));
         testCase.assertTrue(p(1).labels(2)==p(2).labels(2));
      end
      
      function chopCopyLabel(testCase)
         p = testCase.p;
         info = p.info;
         p.window = [1 10; 11 20];
         p.chop('copyLabel',true);
         
         testCase.assertFalse(p(1).labels(1)==p(2).labels(1));
         testCase.assertFalse(p(1).labels(2)==p(2).labels(2));
      end
      
      function chopWithOffset(testCase)
         p = testCase.p;
         p.window = [1 10; 11 20];
         p.offset = [1 2];
         p.chop();

         testCase.assertEqual([p.offset],[1 2]);
         testCase.assertEqual([p.cumulOffset],[1 2]);
         
         testCase.assertEqual(p(1).times{1},1+[(0:9)',.5+(0:9)'],testCase.tolType,testCase.tol);
         testCase.assertEqual(p(1).times{2},zeros(0,2),testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).times{1},zeros(0,2),testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).times{2},2+[(0:9)',.5+(0:9)'],testCase.tolType,testCase.tol);

         values = testCase.ev{1};
         temp = num2cell(1 + (0:9));
         [values(:).tStart] = temp{:};
         temp = num2cell(1 + (0:9) + .5);
         [values(:).tEnd] = temp{:};
         testCase.assertEqual(p(1).values{1},values,testCase.tolType,testCase.tol);
         
         values = testCase.ev{2};
         values(1:9) = [];
         values(1,:) = [];
         testCase.assertEqual(p(1).values{2},values,testCase.tolType,testCase.tol);

         values = testCase.ev{1};
         temp = num2cell(2 + (0:9));
         [values(:).tStart] = temp{:};
         temp = num2cell(2 + (0:9) + .5);
         [values(:).tEnd] = temp{:};
         testCase.assertEqual(p(2).values{2},values,testCase.tolType,testCase.tol);
         
         values = testCase.ev{2};
         values(1:9) = [];
         values(1,:) = [];
         testCase.assertEqual(p(2).values{1},values,testCase.tolType,testCase.tol);
      end
      
      function chopWithOffset2(testCase)
         p = testCase.p;
         p.window = [1 10; 11 20];
         p.offset = [1 2];
         p.offset = [1 2];
         p.chop();

         testCase.assertEqual([p.offset],[1 2]);
         testCase.assertEqual([p.cumulOffset],[2 4]);
         
         testCase.assertEqual(p(1).times{1},2+[(0:9)',.5+(0:9)'],testCase.tolType,testCase.tol);
         testCase.assertEqual(p(1).times{2},zeros(0,2),testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).times{1},zeros(0,2),testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).times{2},4+[(0:9)',.5+(0:9)'],testCase.tolType,testCase.tol);
         
         values = testCase.ev{1};
         temp = num2cell(2 + (0:9));
         [values(:).tStart] = temp{:};
         temp = num2cell(2 + (0:9) + .5);
         [values(:).tEnd] = temp{:};
         testCase.assertEqual(p(1).values{1},values,testCase.tolType,testCase.tol);
         
         values = testCase.ev{2};
         values(1:9) = [];
         values(1,:) = [];
         testCase.assertEqual(p(1).values{2},values,testCase.tolType,testCase.tol);

         values = testCase.ev{1};
         temp = num2cell(4 + (0:9));
         [values(:).tStart] = temp{:};
         temp = num2cell(4 + (0:9) + .5);
         [values(:).tEnd] = temp{:};
         testCase.assertEqual(p(2).values{2},values,testCase.tolType,testCase.tol);
         
         values = testCase.ev{2};
         values(1:9) = [];
         values(1,:) = [];
         testCase.assertEqual(p(2).values{1},values,testCase.tolType,testCase.tol);
      end
      
      function chopAfterSubset(testCase)
         p = testCase.p;
         p.window = [1 10; 11 20];
         p.subset(2);
         p.chop();

         testCase.assertTrue(numel(p(1).labels)==1);
         testCase.assertTrue(numel(p(2).labels)==1);
         testCase.assertTrue(p(1).labels==p(2).labels);
         
         testCase.assertEqual(p(1).times,{zeros(0,2)},testCase.tolType,testCase.tol);
         testCase.assertEqual(p(2).times,{[(0:9)',.5+(0:9)']},testCase.tolType,testCase.tol);

         values = testCase.ev{2};
         values(1:9) = [];
         values(1,:) = [];
         testCase.assertEqual(p(1).values{1},values,testCase.tolType,testCase.tol);

         values = testCase.ev{1};
         temp = num2cell((0:9));
         [values(:).tStart] = temp{:};
         temp = num2cell((0:9) + .5);
         [values(:).tEnd] = temp{:};
         testCase.assertEqual(p(2).values{1},values,testCase.tolType,testCase.tol);

      end      
   end
   
end

