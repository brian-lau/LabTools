%Chenxinfeng, Huazhong University of Science and Technology
%2016-1-12

% Copyright (c) 2016, chen xinfeng(?????????)
% Copyright (c) 2007, John D'Errico
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
%     * Neither the name of the Huazhong University of Science and Technology nor the names
%       of its contributors may be used to endorse or promote products derived
%       from this software without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.
classdef dragLine < handle & hgsetget
   properties (SetAccess = protected,Hidden)
      lh_Start; %????event
      lh_Draging;
      lh_End;
      lh_reFreshLim;
   end
   properties (SetAccess = protected)
      model; %'x'??'y'
      hline; %??????????
      h
   end
   properties (SetObservable=true) %????????????
      color='r';
      linewidth = 2;
      visible = 'on';
   end
   properties
      point; %????????????????
      
      %?????????? ????????
      %????????@ll1   function ll1(hobj,evnt); ????????????2??????
      %????1=???? dragLine_hobj,
      %????2=EventData????<.Source == ????1; EventName='evnt_Darging'>
      StartDragCallback;
      DragingCallback;
      EndDragCallback;
   end
   properties (Access = private)
      saveWindowFcn;
      dargPointer;
   end
   events
      evnt_StartDarg;
      evnt_Darging;
      evnt_EndDarg;
   end
   
   
   methods %????
      function hobj= dragLine(model,point,h)
         if ~exist('model','var');model='x';end
         model = lower(model);
         if ~strcmp(model,'x')
            if ~strcmp(model,'y'); error('model??''x''??''y''');end;
         end
         hobj.model = lower(model);
         
         hobj.h = h;

         %???? line
         xylim = [h.XLim h.YLim];%axis;
         if hobj.model == 'x'
            if ~exist('point','var');point=mean(xylim(1:2));end
            xdata = point*[1 1];
            ydata = xylim(3:4);
            hobj.dargPointer='left'; %drag????????
         else
            if ~exist('point','var');point=mean(xylim(3:4));end
            xdata = xylim(1:2);
            ydata = point*[1 1];
            hobj.dargPointer='top';
         end
         hobj.point = point;
         hobj.hline = plot(xdata,ydata,...
            'color',hobj.color,...
            'linewidth',hobj.linewidth,'Parent',h);
         set(hobj.hline,'ButtonDownFcn',@hobj.FcnStartDrag)
         
         %????????????????????
         addlistener(hobj,'color','PostSet',@hobj.SetInnerProp);
         addlistener(hobj,'linewidth','PostSet',@hobj.SetInnerProp);
         addlistener(hobj,'visible','PostSet',@hobj.SetInnerProp);
         %set this line chang when axis-range chang.

         %axis([xlim ylim]); %must a fix axis
         if hobj.model == 'x'
            hobj.lh_reFreshLim=addlistener(h,'MarkedClean',@(x,y)set(hobj.hline,'ydata',xylim(3:4)) );
         else
            hobj.lh_reFreshLim=addlistener(h,'MarkedClean',@(x,y)set(hobj.hline,'xdata',xylim(1:2)) );
         end
      end
      
      function set.point(hobj,point)
         hobj.point = point;
         if ~ishandle(hobj.hline); return;end; %??????????????
         switch hobj.model
            case 'x'
               %????????
               set(hobj.hline,'xdata',point*[1 1]);
            case 'y'
               set(hobj.hline,'ydata',point*[1 1]);
         end
      end
      
      %????????lh, ??????????????????callback
      function set.StartDragCallback(hobj,hfcn)
         delete(hobj.lh_Start);
         if isempty(hfcn);hfcn=@(x,y)[];end;
         hobj.StartDragCallback = hfcn;
         hobj.lh_Start = addlistener(hobj,'evnt_StartDarg',hfcn);
      end
      function set.DragingCallback(hobj,hfcn)
         delete(hobj.lh_Draging);
         if isempty(hfcn);hfcn=@(x,y)[];end;
         hobj.DragingCallback = hfcn;
         hobj.lh_Draging = addlistener(hobj,'evnt_Darging',hfcn);
      end
      function set.EndDragCallback(hobj,hfcn)
         delete(hobj.lh_End);
         if isempty(hfcn);hfcn=@(x,y)[];end;
         hobj.EndDragCallback = hfcn;
         hobj.lh_End = addlistener(hobj,'evnt_EndDarg',hfcn);
      end
      function delete(hobj)
         %??clear dl1 ??????????????????????delete.
         delete(hobj.hline);
         %disp('??????')
         delete(hobj.lh_reFreshLim);
      end
      
   end
   
   methods (Access = private) %????,drag?????????????????? drag????
      function FcnStartDrag(hobj,varargin)
         g = ancestor(hobj.h,'Figure');
         %??????????????windowfcn
         set(g,'pointer',hobj.dargPointer);
         hobj.saveWindowFcn.Motion = get(g,'WindowButtonMotionFcn');
         hobj.saveWindowFcn.Up = get(g,'WindowButtonUpFcn');
         set(g,'WindowButtonMotionFcn',@hobj.FcnDraging);
         set(g,'WindowButtonUpFcn',@hobj.FcnEndDrag);
         %??????????????????????StartDragCallback
         notify(hobj,'evnt_StartDarg');
      end
      function FcnDraging(hobj,varargin)
         pt = get(hobj.h,'CurrentPoint');
         xpoint = pt(1,1);
         ypoint = pt(1,2);
         switch hobj.model
            case 'x'
               hobj.point = xpoint; %set ???????? line??????????
               %                     set(hobj.hline,'xdata',xpoint*[1 1]);
            case 'y'
               hobj.point = ypoint;
               %                     set(hobj.hline,'ydata',ypoint*[1 1]);
         end
         %??????????????????????DragingCallback
         notify(hobj,'evnt_Darging');
      end
      function FcnEndDrag(hobj,varargin)
         g = ancestor(hobj.h,'Figure');
         %????????????windowfcn
         set(g,'pointer','arrow');
         set(g,'WindowButtonMotionFcn',hobj.saveWindowFcn.Motion);
         set(g,'WindowButtonUpFcn',hobj.saveWindowFcn.Up);
         %??????????????????????EndDragCallback
         notify(hobj,'evnt_EndDarg');
      end
      function SetInnerProp(hobj,varargin)
         set(hobj.hline,'color',hobj.color);
         set(hobj.hline,'linewidth',hobj.linewidth);
         set(hobj.hline,'visible',hobj.visible);
      end
   end
end
