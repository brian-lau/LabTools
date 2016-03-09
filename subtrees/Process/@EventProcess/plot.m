function varargout = plot(self,varargin)
   p = inputParser;
   p.KeepUnmatched = true;
   p.FunctionName = 'EventProcess plot method';
   p.addParameter('handle',[],@(x) isnumeric(x) || ishandle(x));
   p.addParameter('overlay',false);
   p.parse(varargin{:});
   par = p.Results;
   %params = p.Unmatched;

   if isempty(par.handle) || ~ishandle(par.handle)
      figure;
      h = subplot(1,1,1);
   else
      h = par.handle;
   end
   hold on;
   xlim = get(h,'xlim');
   ylim = get(h,'ylim');

   if numel(self) > 1
      self = self(1);
   end
   
   menu = uicontextmenu();
   % Create top-level menu item
   topmenu = uimenu('Parent',menu,'Label','Add event');
   validEventTypes = {'Generic' 'Artifact' 'Stimulus' 'Response'};
   for i = 1:numel(validEventTypes)
      uimenu('Parent',topmenu,'Label',validEventTypes{i},'Callback',{@addEvent self h validEventTypes{i}});
   end
   set(h,'uicontextmenu',menu);

   values = self.values{1};
   for i = 1:numel(values)
      if par.overlay
         plotEvent(values(i),self,h,ylim(2),ylim(1),0.15);
      else
         d = 0.07*diff(ylim);
         d2 = (d/numel(values));
         plotEvent(values(i),self,h,ylim(2)+d2*i,ylim(2)+d2*(i-1),0.4);
         axis([xlim  ylim(1) ylim(2)+d]);
      end
   end

   if nargout >= 1
      varargout{1} = h;
   end
end

function plotEvent(event,obj,h,top,bottom,alpha)
   left = event.time(1);
   right = event.time(2);

   eventMenu = uicontextmenu();
   m1 = uimenu('Parent',eventMenu,'Label','Edit','Callback',{@editEvent obj});
   m2 = uimenu('Parent',eventMenu,'Label','Move','Callback',{@moveEvent obj h});
   m3 = uimenu('Parent',eventMenu,'Label','Delete','Callback',{@deleteEvent obj h});
   m4 = uimenu('Parent',eventMenu,'Label','Change color','Callback',{@pickColor obj h});
   set([m1 m2 m3 m4],'UserData',event.name,'Tag','Event');

   try
      color = event.name.color;
   catch
      color = [0 0 0];
   end
   
   if event.duration == 0
      eGraphic = line([left left],[bottom top],'Color',color,'Linewidth',2,'Parent',h);
      set(eGraphic,'UserData',event.name,'Tag','Event'); % Store event name 
      set(eGraphic,'uicontextmenu',eventMenu);
   else
      eGraphic = fill([left left right right],[bottom top top bottom],...
         color,'FaceAlpha',alpha,'EdgeColor','none','Parent',h);
      set(eGraphic,'UserData',event.name,'Tag','Event');
      set(eGraphic,'uicontextmenu',eventMenu);
   end
   
   try
      name = event.name.name;
   catch
      name = event.name;
   end
       
   eText = text(left,top,name,'VerticalAlignment','bottom',...
      'FontAngle','italic','Color',color,'Parent',h);
   set(eText,'UserData',event.name,'Tag','Event');
end

function setLabels(h,label)
   th = findall(h,'Tag','Event','Type','Text');
   ind = find([th.UserData]==label);
   for i = ind
      th(i).String = th(i).UserData.name;
      th(i).Color = th(i).UserData.color;
   end
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
      plotEvent(event,obj,h,d.yPoints(2),d.yPoints(1));
      delete(d);
      set(g,'WindowKeyPressFcn','');
   end
end

function editEvent(source,~,obj)
	event = find(obj,'eventProp','name','eventVal',source.UserData);
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
	event = find(obj,'eventProp','name','eventVal',source.UserData);
   
   obj.remove(event.time(1));
   g = findobj(h,'UserData',source.UserData);
   delete(g);
   m = get(source,'parent');
   delete(m);
end

function pickColor(~,~,obj,h)
   ph = gco;
   event = find(obj,'eventProp','name','eventVal',ph.UserData);
   
   color = event.name.color;

   cc = javax.swing.JColorChooser;
   cp = cc.getChooserPanels;
   cc.setChooserPanels(cp([4 1]));
   cc.setColor(fix(color(1)*255),fix(color(2)*255),fix(color(3)*255));

   mouse = get(0,'PointerLocation');
   d = dialog('Position',[mouse 610 425],'Name','Select color');
   javacomponent(cc,[1,1,610,425],d);
   uiwait(d);
   color = cc.getColor;
   
   event.name.color(1) = color.getRed/255;
   event.name.color(2) = color.getGreen/255;
   event.name.color(3) = color.getBlue/255;
   ph.FaceColor = event.name.color;
   
   setLabels(h,event.name);
end
