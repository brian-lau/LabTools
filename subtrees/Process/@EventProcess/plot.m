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
   %xlim = get(h,'xlim');
   ylim = get(h,'ylim');

   menu = uicontextmenu();
   % Create top-level menu item
   topmenu = uimenu('Parent',menu,'Label','Add event');
   validEventTypes = {'Generic' 'Artifact' 'Stimulus' 'Response'};
   for i = 1:numel(validEventTypes)
      uimenu('Parent',topmenu,'Label',validEventTypes{i},'Callback',{@addEvent self h validEventTypes{i}});
   end
   set(h,'uicontextmenu',menu);

   values = self.values{1};
   c = fig.distinguishable_colors(numel(values));
   %c = rand(100,3);
   for i = 1:numel(values)
      plotEvent(values(i),self,h,c(i,:),ylim(2),ylim(1));
   end

   if nargout >= 1
      varargout{1} = h;
   end
end

function plotEvent(event,obj,h,color,top,bottom)
   left = event.time(1);
   right = event.time(2);

   eventMenu = uicontextmenu();
   m1 = uimenu('Parent',eventMenu,'Label','Edit','Callback',{@editEvent obj});
   m2 = uimenu('Parent',eventMenu,'Label','Move','Callback',{@moveEvent obj h});
   m3 = uimenu('Parent',eventMenu,'Label','Delete','Callback',{@deleteEvent obj h});
   set([m1 m2 m3],'Tag',event.name);

   eFill = fill([left left right right],[bottom top top bottom],...
      color,'FaceAlpha',0.15,'EdgeColor','none','Parent',h);
   set(eFill,'Tag',event.name);
   set(eFill,'uicontextmenu',eventMenu);

   eText = text(left,top,event.name,'VerticalAlignment','bottom',...
      'FontAngle','italic','Parent',h);
   set(eText,'Tag',event.name);
end

function addEvent(source,data,obj,h,eventType)
   d = dragRect('xx');
   set(d,'EndDragCallback',@(hobj,evnt)disp('now drag end'));
   set(gcf,'WindowKeyPressFcn',{@clickcallback obj h eventType d});
end

function editEvent(source,~,obj)
	event = find(obj,'name',source.Tag);
   propertiesGUI(event);
end

function moveEvent(source,~,obj,h)
   p = findobj(h,'Tag',source.Tag,'-and','Type','patch');
   setptr(gcf,'hand');
   fig.movepatch(p,'x');
   waitfor(gcf,'UserData','stop');
   set(gcf,'UserData',[]);
   v = get(p,'Vertices');
   
   q = linq(obj.values{1});
   ind = find(q.select(@(x) strcmp(x.name,source.Tag)).toArray());
   event = obj.values{1}(ind);

   event.tStart = v(1,1);
   event.tEnd = v(3,1);
   obj.values{1}(ind) = event;
   obj.times{1}(ind,:) = [v(1,1) v(3,1)];
   g = findobj(h,'Tag',source.Tag,'-and','Type','Text');
   g.Position(1) = v(1,1);
end

function deleteEvent(source,~,obj,h)
   % could use    get(gcf, 'CurrentObject') or perhaps hittest to resolve
   % multiple events (eg, same name)
	event = find(obj,'name',source.Tag);
   obj.remove(event.time(1));
   g = findobj(h,'Tag',source.Tag);
   delete(g);
   m = get(source,'parent');
   delete(m);
end

function clickcallback(~,~,obj,h,eventType,d)
   event = metadata.event.(eventType);
   event.name = 'junk';
   event.tStart = d.xPoints(1);
   event.tEnd = d.xPoints(2);
   obj.insert(event);
   plotEvent(event,obj,h,[0 0 0],d.yPoints(2),d.yPoints(1));
   delete(d);
end