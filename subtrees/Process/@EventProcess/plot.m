function varargout = plot(self,varargin)
   p = inputParser;
   p.KeepUnmatched= true;
   p.FunctionName = 'EventProcess plot method';
   p.addParameter('handle',[],@(x) isnumeric(x) || ishandle(x));
   p.parse(varargin{:});
   params = p.Unmatched;

   if isempty(p.Results.handle) || ~ishandle(p.Results.handle)
      figure;
      h = subplot(1,1,1);
   else
      h = p.Results.handle;
   end
   hold on;
   ylim = get(h,'ylim');

   menu = uicontextmenu();
   % Create top-level menu item
   m1 = uimenu('Parent',menu,'Label','Add','Callback',{@add self h});
   set(h,'uicontextmenu',menu);

   values = self.values{1};
   c = fig.distinguishable_colors(numel(values));
   %c = rand(100,3);
   for i = 1:numel(values)
      left = values(i).time(1);
      right = values(i).time(2);
      bottom = ylim(1);
      top = ylim(2);
      eFill(i) = fill([left left right right],[bottom top top bottom],...
         c(i,:),'FaceAlpha',0.15,'EdgeColor','none','Parent',h);
      set(eFill(i),'Tag',values(i).name);

      eventMenu = uicontextmenu();
      m1 = uimenu('Parent',eventMenu,'Label','Edit','Callback',{@editEvent values(i)});
      m2 = uimenu('Parent',eventMenu,'Label','Move','Callback',{@moveEvent eFill(i) self i h});
      m3 = uimenu('Parent',eventMenu,'Label','Delete','Callback',{@deleteEvent self values(i) h});
      set([m1 m2 m3],'Tag',values(i).name);
      set(eFill(i),'uicontextmenu',eventMenu);

      eText(i) = text(left,top,values(i).name,'VerticalAlignment','bottom',...
         'FontAngle','italic','Parent',h);
      set(eText(i),'Tag',values(i).name);
   end

   if nargout >= 1
      varargout{1} = h;
   end
end

function add(source,data,obj,h)
d = dragRect('xx');
set(d,'EndDragCallback',@(hobj,evnt)disp('now drag end'));
keyboard
end

function editEvent(~,~,event)
   propertiesGUI(event)
end

function moveEvent(source,~,p,obj,ind,h)
   fig.movepatch(p,'x');
   waitfor(gcf,'UserData','stop');
   set(gcf,'UserData',[]);
   
   v = get(p,'Vertices');
   temp = obj.values{1}(ind);
   temp.tStart = v(1,1);
   temp.tEnd = v(3,1);
   obj.values{1}(ind) = temp;
   obj.times{1}(ind,:) = [v(1,1) v(3,1)];
   g = findobj(h,'Tag',source.Tag,'-and','Type','Text');
   g.Position(1) = v(1,1);
end

function deleteEvent(source,~,obj,event,h)
   obj.remove(event.time(1));
   g = findobj(h,'Tag',source.Tag);
   delete(g);
   m = get(source,'parent');
   delete(m);
end
