classdef TestEventProcessFind < matlab.unittest.TestCase
   properties
      tolType = 'AbsTol'
      tol = eps;
      p
      ev
   end
   
   methods(TestMethodSetup)
      function setup(testCase)
         ev(1) = metadata.event.Stimulus('tStart',0.5,'tEnd',1,'name','fix');
         ev(2) = metadata.event.Response('tStart',5,'tEnd',6,'name','button','modality','hand');
         ev(3) = metadata.event.Stimulus('tStart',2,'tEnd',3,'name','cue');
         ev(4) = metadata.event.Stimulus('tStart',6,'tEnd',7,'name','feedback');
         
         testCase.p = EventProcess('events',ev,'tStart',0,'tEnd',10);
         testCase.ev = ev;
      end
   end
   
   methods(TestMethodTeardown)
      function teardown(testCase)
         testCase.p = [];
         testCase.ev = [];
      end
   end
   
   methods (Test)
      function findEventTypeNull(testCase)
         p = testCase.p;
         
         ev = p.find('eventType','test');
         
         testCase.assertEqual(ev.name,'NULL');
         testCase.assertEqual(ev.tStart,NaN);
         testCase.assertEqual(ev.tEnd,NaN);
      end
      
      function findEventType(testCase)
         p = testCase.p;
         
         ev = p.find('eventType','metadata.event.Response');
         
         testCase.assertEqual(ev.name,'button');
         testCase.assertEqual(ev.tStart,5);
         testCase.assertEqual(ev.tEnd,6);
      end
      
      function findEventTypeAll(testCase)
         p = testCase.p;
         
         ev = p.find('eventType','metadata.event.Stimulus','policy','all');
         
         testCase.assertEqual(ev{1}(1).name,'fix');
         testCase.assertEqual(ev{1}(2).name,'cue');
         testCase.assertEqual(ev{1}(1).tStart,0.5);
         testCase.assertEqual(ev{1}(1).tEnd,1);
         testCase.assertEqual(ev{1}(2).tStart,2);
         testCase.assertEqual(ev{1}(2).tEnd,3);
      end
      
      function findEventTypeLast(testCase)
         p = testCase.p;
         
         ev = p.find('eventType','metadata.event.Stimulus','policy','last');
         
         testCase.assertEqual(ev.name,'feedback');
         testCase.assertEqual(ev.tStart,6);
         testCase.assertEqual(ev.tEnd,7);
      end
      
      function findEventValNull(testCase)
         p = testCase.p;
         
         ev = p.find('eventVal','test');
         
         testCase.assertEqual(ev.name,'NULL');
         testCase.assertEqual(ev.tStart,NaN);
         testCase.assertEqual(ev.tEnd,NaN);
      end
      
      function findEventVal(testCase)
         p = testCase.p;
         
         ev = p.find('eventVal','button');
         
         testCase.assertEqual(ev.name,'button');
         testCase.assertEqual(ev.tStart,5);
         testCase.assertEqual(ev.tEnd,6);
      end
      
      function findEventValAll(testCase)
         p = testCase.p;
         
         ev = p.find('eventProp','duration','eventVal',1,'policy','all');

         testCase.assertEqual(ev{1}(2).name,'button');
         testCase.assertEqual(ev{1}(1).name,'cue');
         testCase.assertEqual(ev{1}(2).tStart,5);
         testCase.assertEqual(ev{1}(2).tEnd,6);
         testCase.assertEqual(ev{1}(1).tStart,2);
         testCase.assertEqual(ev{1}(1).tEnd,3);
      end
      
      function findEventValLast(testCase)
         p = testCase.p;
         
         ev = p.find('eventVal','cue','policy','last');
         
         testCase.assertEqual(ev.name,'cue');
         testCase.assertEqual(ev.tStart,2);
         testCase.assertEqual(ev.tEnd,3);
      end
      
      function findFuncNull(testCase)
         p = testCase.p;
         
         ev = p.find('func',@(x) x.tStart<0);
         
         testCase.assertEqual(ev.name,'NULL');
         testCase.assertEqual(ev.tStart,NaN);
         testCase.assertEqual(ev.tEnd,NaN);
      end
      
      function findFunc(testCase)
         p = testCase.p;
         
         ev = p.find('func',@(x) x.tStart>=2);
         
         testCase.assertEqual(ev.name,'cue');
         testCase.assertEqual(ev.tStart,2);
         testCase.assertEqual(ev.tEnd,3);
      end
      
      function findFuncAll(testCase)
         p = testCase.p;
         
         ev = p.find('func',@(x) x.tStart>=2,'policy','all');

         testCase.assertEqual(ev{1}(2).name,'button');
         testCase.assertEqual(ev{1}(1).name,'cue');
         testCase.assertEqual(ev{1}(2).tStart,5);
         testCase.assertEqual(ev{1}(2).tEnd,6);
         testCase.assertEqual(ev{1}(1).tStart,2);
         testCase.assertEqual(ev{1}(1).tEnd,3);
      end
      
      function findFuncLast(testCase)
         p = testCase.p;
         
         ev = p.find('func',@(x) isa(x,'metadata.event.Stimulus'),'policy','last');

         testCase.assertEqual(ev.name,'feedback');
         testCase.assertEqual(ev.tStart,6);
         testCase.assertEqual(ev.tEnd,7);
      end

      function findLogicOR(testCase)
         p = testCase.p;
         
         ev = p.find('eventType','metadata.event.Response','func',@(x) x.tStart>=6,'policy','all');
         
         testCase.assertTrue(numel(ev)==1);
         testCase.assertTrue(numel(ev{1})==2);
         testCase.assertEqual(ev{1}(1).name,'button');
         testCase.assertEqual(ev{1}(2).name,'feedback');
      end
      
      function findLogicAND(testCase)
         p = testCase.p;
         
         ev = p.find('eventType','metadata.event.Stimulus','func',@(x) x.tStart<=2,'policy','all','logic','and');
         
         testCase.assertTrue(numel(ev)==1);
         testCase.assertTrue(numel(ev{1})==2);
         testCase.assertEqual(ev{1}(1).name,'fix');
         testCase.assertEqual(ev{1}(2).name,'cue');
      end
      
      function findLogicXOR(testCase)
         p = testCase.p;
         
         ev = p.find('eventProp','modality','eventVal','hand','func',@(x) x.tStart>=2,'policy','all','logic','xor');

         testCase.assertTrue(numel(ev)==1);
         testCase.assertTrue(numel(ev{1})==2);
         testCase.assertEqual(ev{1}(1).name,'cue');
         testCase.assertEqual(ev{1}(2).name,'feedback');
      end
   end
   
end

