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
      
      HoehnYahr = struct('on',[],'off',[]);
      SchwabEngland = struct('on',[],'off',[]);
   end
   properties(SetAccess = private, Dependent = true, Transient = true)
      I
      II
      III
      IV
      axial
      dyskinesia
      complications
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
      
      function I = get.I(self)
         I = 0;
         for i = 1:4
            I = I + self.(['item' num2str(i)]);
         end
      end
      
      function II = get.II(self)
         II.on = 0;
         II.off = 0;
         for i = 5:17
            II.off = II.off + self.(['item' num2str(i)]).off;
            II.on = II.on + self.(['item' num2str(i)]).on;
         end
      end
      
      function III = get.III(self)
         fn = properties(self);
         ind1 = find(strcmp('item18',fn));
         ind2 = find(strcmp('item31',fn));
         III = struct('offStim',struct('onMed',0,'offMed',0),...
                      'onStim',struct('onMed',0,'offMed',0));
         for i = ind1:ind2
            III.onStim.offMed = III.onStim.offMed + self.(fn{i}).onStim.offMed;
            III.offStim.offMed = III.offStim.offMed + self.(fn{i}).offStim.offMed;
            III.offStim.onMed = III.offStim.onMed + self.(fn{i}).offStim.onMed;
            III.onStim.onMed = III.onStim.onMed + self.(fn{i}).onStim.onMed;
         end
      end
      
      function IV = get.IV(self)
         IV = 0;
         for i = 32:42
            IV = IV + self.(['item' num2str(i)]);
         end
      end
      
      function axial = get.axial(self)
         axial = struct('offStim',struct('onMed',0,'offMed',0),...
                      'onStim',struct('onMed',0,'offMed',0));
         axial.onStim.offMed = self.item18.onStim.offMed + self.item27.onStim.offMed +...
            self.item28.onStim.offMed + self.item29.onStim.offMed + self.item30.onStim.offMed;
         axial.offStim.offMed = self.item18.offStim.offMed + self.item27.offStim.offMed +...
            self.item28.offStim.offMed + self.item29.offStim.offMed + self.item30.offStim.offMed;
         axial.offStim.onMed = self.item18.offStim.onMed + self.item27.offStim.onMed +...
            self.item28.offStim.onMed + self.item29.offStim.onMed + self.item30.offStim.onMed;
         axial.onStim.onMed = self.item18.onStim.onMed + self.item27.onStim.onMed +...
            self.item28.onStim.onMed + self.item29.onStim.onMed + self.item30.onStim.onMed;
      end
      
      function dyskinesia = get.dyskinesia(self)
         dyskinesia = self.item32 + self.item33 + self.item34 + self.item35;
      end
      
      function complications = get.complications(self)
         complications = self.item40 + self.item41 + self.item42;
      end
     
      function disp(self,fid)
         
         if numel(self) > 1
            for i = 1:numel(self)
               fprintf('\n');
               disp(self(i));
            end
            return;
         end
         
         if nargin == 1
            fid = 1;
         end
         fn = properties(self);

         fprintf(fid,'---------------------------------------------------------------------------\n');
         fprintf(fid,'PatientID:\t%s\n',self.name);
         fprintf(fid,'Exam:\t\t%s\n',self.type);
         fprintf(fid,'Date:\t\t%s, %s',datestr(self.date,self.dateFormat),self.description);
         
         fprintf(fid,'\n-------------------- PART I -----------------------------------------------\n');
         for i = 1:4
            fprintf(fid,'Item %s\t\t%g\n',num2str(i),self.(['item' num2str(i)]));
         end
         fprintf(fid,'TOTAL\t\t%g',self.I);
         
         fprintf(fid,'\n-------------------- PART II ----------------------------------------------\n');
         fprintf(fid,'\t\tOFF\tON\n');
         fprintf(fid,'---------------------------------------------------------------------------\n');
         for i = 5:17
            fprintf(fid,'Item %s\t\t%g\t%g\n',num2str(i),self.(['item' num2str(i)]).off,self.(['item' num2str(i)]).on);
         end
         fprintf(fid,'TOTAL\t\t%g\t%g',self.II.off,self.II.on);
         
         fprintf(fid,'\n-------------------- PART III ---------------------------------------------\n');
         fprintf(fid,'\t\tONS-OFFM\tOFFS-OFFM\tOFFS-ONM\tONS-ONM\n');
         fprintf(fid,'---------------------------------------------------------------------------\n');
         ind1 = find(strcmp('item18',fn));
         ind2 = find(strcmp('item31',fn));
         for i = ind1:ind2
            if numel(fn{i}(5:end)) == 2
               fprintf(fid,'Item %s\t\t',fn{i}(5:end));
            else
               fprintf(fid,'Item %s\t',fn{i}(5:end));
            end
            
            temp = self.(fn{i}).onStim.offMed;
            if isempty(temp)
               fprintf(fid,'-\t\t');
            else
               fprintf(fid,'%g\t\t',temp);
            end
            temp = self.(fn{i}).offStim.offMed;
            if isempty(temp)
               fprintf(fid,'-\t\t');
            else
               fprintf(fid,'%g\t\t',temp);
            end
            temp = self.(fn{i}).offStim.onMed;
            if isempty(temp)
               fprintf(fid,'-\t\t');
            else
               fprintf(fid,'%g\t\t',temp);
            end
            temp = self.(fn{i}).onStim.onMed;
            if isempty(temp)
               fprintf(fid,'-\n');
            else
               fprintf(fid,'%g\n',temp);
            end
         end
         fprintf(fid,'TOTAL\t\t');
         if isempty(self.III.onStim.offMed)
            fprintf(fid,'-\t\t');
         else
            fprintf(fid,'%g\t\t',self.III.onStim.offMed);
         end
         if isempty(self.III.offStim.offMed)
            fprintf(fid,'-\t\t');
         else
            fprintf(fid,'%g\t\t',self.III.offStim.offMed);
         end
         if isempty(self.III.offStim.onMed)
            fprintf(fid,'-\t\t');
         else
            fprintf(fid,'%g\t\t',self.III.offStim.onMed);
         end
         if isempty(self.III.onStim.onMed)
            fprintf(fid,'-\t\t');
         else
            fprintf(fid,'%g\t\t',self.III.onStim.onMed);
         end
         fprintf(fid,'\nAXIAL\t\t');
         if isempty(self.axial.onStim.offMed)
            fprintf(fid,'-\t\t');
         else
            fprintf(fid,'%g\t\t',self.axial.onStim.offMed);
         end
         if isempty(self.axial.offStim.offMed)
            fprintf(fid,'-\t\t');
         else
            fprintf(fid,'%g\t\t',self.axial.offStim.offMed);
         end
         if isempty(self.axial.offStim.onMed)
            fprintf(fid,'-\t\t');
         else
            fprintf(fid,'%g\t\t',self.axial.offStim.onMed);
         end
         if isempty(self.axial.onStim.onMed)
            fprintf(fid,'-\t\t');
         else
            fprintf(fid,'%g\t\t',self.axial.onStim.onMed);
         end
         
         fprintf(fid,'\n-------------------- PART IV ----------------------------------------------\n');
         for i = 32:42
            fprintf(fid,'Item %s\t\t%g\n',num2str(i),self.(['item' num2str(i)]));
         end
         fprintf(fid,'TOTAL\t\t%g\n',self.IV);
         fprintf(fid,'DYSKINESIA\t%g\n',self.dyskinesia);
         fprintf(fid,'COMPLICATIONS\t%g',self.complications);
         
         fprintf(fid,'\n-------------------- PART V/VI --------------------------------------------\n');
         fprintf(fid,'\t\tONS-OFFM\tONS-ONM\n');
         fprintf(fid,'---------------------------------------------------------------------------\n');
         fprintf(fid,'Hoehn&Yahr\t%g\t\t%g\n',self.HoehnYahr.off,self.HoehnYahr.on);
         fprintf(fid,'Schwab&England\t%g\t\t%g\n',self.SchwabEngland.off,self.SchwabEngland.on);
         
         fprintf(fid,'---------------------------------------------------------------------------\n');
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
                  if ((x.(fn{i})>=0) && (x.(fn{i})<=4)) || isnan(x.(fn{i}))
                     y(count) = x.(fn{i});
                     fv{count} = fn{i};
                     count = count + 1;
                  else
                     error('UPDRS:InputValue','Invalid value');
                  end
%                   assert((x.(fn{i})>=0)&&(x.(fn{i})<=4),...
%                      'UPDRS:InputValue','Invalid value');
%                   y(count) = x.(fn{i});
%                   fv{count} = fn{i};
%                   count = count + 1;
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
                        if ((x.(fn1{i}).(fn2{j})>=0)&&(x.(fn1{i}).(fn2{j})<=4)) || isnan(x.(fn1{i}).(fn2{j}))
                           y(count) = x.(fn1{i}).(fn2{j});
                           fv1{count} = fn1{i};
                           fv2{count} = fn2{j};
                           count = count + 1;
                        else
                           error('UPDRS:InputValue','Invalid value');
                        end
%                         assert((x.(fn1{i}).(fn2{j})>=0)&&(x.(fn1{i}).(fn2{j})<=4),...
%                            'UPDRS:InputValue','Invalid value');
%                         y(count) = x.(fn1{i}).(fn2{j});
%                         fv1{count} = fn1{i};
%                         fv2{count} = fn2{j};
%                         count = count + 1;
                     end
                  end
               end
            end
         end
      end
      
   end
end