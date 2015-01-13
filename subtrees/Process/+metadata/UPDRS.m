classdef UPDRS < metadata.Exam
   properties
      %LEDD %?
      item1
      item2
      item3
      item4
      item5 = struct('on',[],'off',[]);
      item6 = struct('on',[],'off',[]);
      item7 = struct('on',[],'off',[]);
      item8 = struct('on',[],'off',[]);
      item9 = struct('on',[],'off',[]);
      item10 = struct('on',[],'off',[]);
      item11 = struct('on',[],'off',[]);
      item12 = struct('on',[],'off',[]);
      item13 = struct('on',[],'off',[]);
      item14 = struct('on',[],'off',[]);
      item15 = struct('on',[],'off',[]);
      item16 = struct('on',[],'off',[]);
      item17 = struct('on',[],'off',[]);
      item18 = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item19 = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item20a = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item20b = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item20c = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item20d = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item20e = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item21a = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item21b = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item22a = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item22b = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item22c = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item22d = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item22e = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item23a = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item23b = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item24a = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item24b = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item25a = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item25b = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item26a = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item26b = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item27 = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item28 = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item29 = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item30 = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item31 = struct('offStim',struct('onMed',[],'offMed',[]),...
                      'onStim',struct('onMed',[],'offMed',[]));
      item32
      item33
      item34
      item35
      item36
      item37
      item38
      item39
      item40
      item41
      item42
      
      HoehnYahr
      SchwabEngland
   end
   properties(SetAccess = private, Dependent = true, Transient = true)
      akinesia
      bradykinesia
      tremor
   end
   
   methods
      function self = UPDRS(varargin)
         self = self@metadata.Exam(varargin{:});
         if nargin == 0
            return;
         end
      end
      
      function set.item1(self,x)
         assert((x>=0)&&(x<=4),'UPDRS:InputValue','Invalid value');
         self.item1 = x;
      end
      
      function set.item2(self,x)
         assert((x>=0)&&(x<=4),'UPDRS:InputValue','Invalid value');
         self.item2 = x;
      end
      
      function set.item3(self,x)
         assert((x>=0)&&(x<=4),'UPDRS:InputValue','Invalid value');
         self.item3 = x;
      end
      
      function set.item4(self,x)
         assert((x>=0)&&(x<=4),'UPDRS:InputValue','Invalid value');
         self.item4 = x;
      end

      function set.item5(self,x)
         [y,fn] = self.validateItem(x);
         for i = 1:numel(y)
            self.item5.(fn{i}) = y(i);
         end
      end

      function set.item6(self,x)
         [y,fn] = self.validateItem(x);
         for i = 1:numel(y)
            self.item6.(fn{i}) = y(i);
         end
      end
      
      function set.item7(self,x)
         [y,fn] = self.validateItem(x);
         for i = 1:numel(y)
            self.item7.(fn{i}) = y(i);
         end
      end
      
      function set.item8(self,x)
         [y,fn] = self.validateItem(x);
         for i = 1:numel(y)
            self.item8.(fn{i}) = y(i);
         end
      end
      
      function set.item9(self,x)
         [y,fn] = self.validateItem(x);
         for i = 1:numel(y)
            self.item9.(fn{i}) = y(i);
         end

      end
      
      function set.item10(self,x)
         [y,fn] = self.validateItem(x);
         for i = 1:numel(y)
            self.item10.(fn{i}) = y(i);
         end
      end
      
      function set.item11(self,x)
         [y,fn] = self.validateItem(x);
         for i = 1:numel(y)
            self.item11.(fn{i}) = y(i);
         end
      end
      
      function set.item12(self,x)
         [y,fn] = self.validateItem(x);
         for i = 1:numel(y)
            self.item12.(fn{i}) = y(i);
         end

      end
      
      function set.item13(self,x)
         [y,fn] = self.validateItem(x);
         for i = 1:numel(y)
            self.item13.(fn{i}) = y(i);
         end

      end
      
      function set.item14(self,x)
         [y,fn] = self.validateItem(x);
         for i = 1:numel(y)
            self.item14.(fn{i}) = y(i);
         end

      end
      
      function set.item15(self,x)
         [y,fn] = self.validateItem(x);
         for i = 1:numel(y)
            self.item15.(fn{i}) = y(i);
         end
      end
      
      function set.item16(self,x)
         [y,fn] = self.validateItem(x);
         for i = 1:numel(y)
            self.item16.(fn{i}) = y(i);
         end
      end
      
      function set.item17(self,x)
         [y,fn] = self.validateItem(x);
         for i = 1:numel(y)
            self.item17.(fn{i}) = y(i);
         end
      end
            
      function set.item18(self,x)
         [y,fn1,fn2] = self.validateItem2(x);
         for i = 1:numel(y)
            self.item18.(fn1{i}).(fn2{i}) = y(i);
         end
      end
   end
   
   methods(Static)
      function [y,fv] = validateItem(x)
         fn = fieldnames(x);
         count = 1;
         y = [];
         fv = {};
         for i = 1:numel(fn)
            if any(strcmp(fn{i},{'on' 'off'}))
               if ~isempty(x.(fn{i}))
                  assert((x.(fn{i})>=0)&&(x.(fn{i})<=4),...
                     'UPDRS:InputValue','Invalid value');
                  y(count) = x.(fn{i});
                  fv{count} = fn{i};
                  count = count + 1;
               end
            end
         end
      end
      
      function [y,fv1,fv2] = validateItem2(x)
         fn1 = fieldnames(x);
         count = 1;
         y = [];
         fv1 = {};
         fv2 = {};
         for i = 1:numel(fn1)
            if any(strcmp(fn1{i},{'offStim' 'onStim'}))
               fn2 = fieldnames(x.(fn1{i}));
               for j = 1:numel(fn2)
                  if any(strcmp(fn2{j},{'offMed' 'onMed'}))
                     if ~isempty(x.(fn1{i}).(fn2{j}))
                        assert((x.(fn1{i}).(fn2{j})>=0)&&(x.(fn1{i}).(fn2{j})<=4),...
                           'UPDRS:InputValue','Invalid value');
                        y(count) = x.(fn1{i}).(fn2{j});
                        fv1{count} = fn1{i};
                        fv2{count} = fn2{j};
                        count = count + 1;
                     end
                  end
               end
            end
         end
      end
      
   end
end