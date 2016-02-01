function varargout = plot(self,varargin)
   p = inputParser;
   p.KeepUnmatched = true;
   p.FunctionName = 'EventProcess plot method';
   p.addParameter('handle',[],@(x) isnumeric(x) || ishandle(x));
   p.parse(varargin{:});
   %params = p.Unmatched;

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
   set([m1 m2 m3],'UserData',event.name,'Tag','Event');

   if event.duration == 0
      eGraphic = line([left left],[bottom top],'Color',color,'Linewidth',2,'Parent',h);
      set(eGraphic,'UserData',event.name,'Tag','Event'); % Store event name 
      set(eGraphic,'uicontextmenu',eventMenu);
   else
      eGraphic = fill([left left right right],[bottom top top bottom],...
         color,'FaceAlpha',0.15,'EdgeColor','none','Parent',h);
      set(eGraphic,'UserData',event.name,'Tag','Event');
      set(eGraphic,'uicontextmenu',eventMenu);
   end
   
   eText = text(left,top,event.name,'VerticalAlignment','bottom',...
      'FontAngle','italic','Parent',h);
   set(eText,'UserData',event.name,'Tag','Event');
end

function addEvent(~,~,obj,h,eventType)
   d = dragRect('xx');
   g = ancestor(h,'Figure');
   set(g,'WindowKeyPressFcn',{@keypressEvent});
   
   function keypressEvent(~,~)
      event = metadata.event.(eventType);
      name = inputdlg('Event name:','Event name');
      event.name = name{1};
      if d.xPoints(1) <= d.xPoints(2)
         event.tStart = d.xPoints(1);
         event.tEnd = d.xPoints(2);
      else
         event.tStart = d.xPoints(2);
         event.tEnd = d.xPoints(1);
      end
      obj.insert(event);
      plotEvent(event,obj,h,[0 0 0],d.yPoints(2),d.yPoints(1));
      delete(d);
      set(g,'WindowKeyPressFcn','');
   end
end

function editEvent(source,~,obj)
	event = find(obj,'name',source.UserData);
   propertiesGUI(event);
end

function moveEvent(source,~,obj,h)   
   p = findobj(h,'UserData',source.UserData,'-and','Type','patch');
   if isempty(p)
      p = findobj(h,'UserData',source.UserData,'-and','Type','line');
   end
   setptr(gcf,'hand');
   fig.movepatch(p,'x',@mouseupEvent);

   function mouseupEvent(~,~)
      if isa(p,'matlab.graphics.primitive.Line')
         tStart = p.XData(1);
         tEnd = tStart;
      else
         v = get(p,'Vertices');
         tStart = v(1,1);
         tEnd = v(3,1);
      end
   
      q = linq(obj.values{1});
      ind = find(q.select(@(x) strcmp(x.name,source.UserData)).toArray());
      event = obj.values{1}(ind);

      event.tStart = tStart;
      event.tEnd = tEnd;
      obj.values{1}(ind) = event;
      obj.times{1}(ind,:) = [tStart tEnd];
      g = findobj(h,'UserData',source.UserData,'-and','Type','Text');
      g.Position(1) = tStart;
      % HACK - despite nextplot setting, this gets cleared?
      p.UserData = source.UserData;
   end
end

function deleteEvent(source,~,obj,h)
   % could use    get(gcf, 'CurrentObject') or perhaps hittest to resolve
   % multiple events (eg, same name)
	event = find(obj,'name',source.UserData);
   obj.remove(event.time(1));
   g = findobj(h,'UserData',source.UserData);
   delete(g);
   m = get(source,'parent');
   delete(m);
end
