%Chenxinfeng, Huazhong University of Science and Technology
%2016-1-12
%% demo

clear;
figure;
plot(sin(1:.1:10));
hold on;
%import dragclass.* %if U path they in '+dragclass' dir
%% create 2 hobj:dragLine
%U may 'hold on' before U create this h_dragLine
%When creating, it auto run 'axis([xlim ylim])'!!!
%When creating, the cmd 'axis tight' will not work as Ur expect
dl = dragLine(); %dl = dragLine('x',0);
dl2 = dragLine('y',0.7); 
pause 

%now U try to drag them, and watch 'point' prop
disp(dl.point);
disp(dl2.point);
d1.point=5;
d12.point=1;
pause

%set prop
set(dl,'color','b');pause
set(dl,'color',[1 0 1]);pause
set(dl,'linewidth',6);pause
set(dl,'visible','off');pause
set(dl,'visible','on'); 

%set callbackfun, always a handle with 2 para(but U may not use them). 
set(dl,'StartDragCallback',@(hobj,evnt)disp('now it start'));
set(dl2,'DragingCallback',@(hobj,evnt)disp('now draging'));
set(dl2,'EndDragCallback',@(hobj,evnt)disp('now drag end'));
pause; %only dl2 but not dl reply 

%delete()
delete(dl); %Correct
clear('dl2'); %Wrong. still in figure,Ahh
pause

%% create 3 obj:dragRect
%---composed of dragLine-hobjs and a patch
%---U may mostly interested in Properte--'xyPoints'
%U may 'hold on' before U create this h_dragLine
%When creating, it auto run 'axis([xlim ylim])'!!!
%When creating, the cmd 'axis tight' will not work as Ur expect
clear;clf
plot(sin(1:.1:10));
hold on;
dr = dragRect();
dr2 = dragRect('xx');
dr3 = dragRect('yy',[0 0 -.5 .3]);%3 ¡Á rectangle
set(dr,'color','b');
set(dr2,'color',[1 0 1]);
set(dr3,'color',[0 1 1]);pause;
set(dr3,'visible','off');pause;
set(dr3,'visible','on');pause;
set(dr3,'linewidth',10);pause;
set(dr,'facealpha',0.8);
pause 

%now U try to drag them, and watch 'xyPoints' prop
disp(dr.xyPoints);%disp [xmin xmax ymin ymax]
disp(dr2.xyPoints);
disp(dr3.xyPoints);
pause
dr.xyPoints=[0 10 0.3 5 ];
axis([-5 105 -1 6])
pause

%set callbackfun, same as 'dragLine'. 
set(dr,'StartDragCallback',@(hobj,evnt)disp('now it start'));
set(dr2,'DragingCallback',@(hobj,evnt)disp('now draging'));
set(dr3,'EndDragCallback',@(hobj,evnt)disp('now drag end'));

%use 'delete()' ,same as 'dragLine'. 
delete (dr); %Correct
delete(dr2);
clear('dr3'); %Wrong

%% end demo
clear import