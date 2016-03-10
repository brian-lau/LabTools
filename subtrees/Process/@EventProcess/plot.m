function varargout = plot(self,varargin)

   p = inputParser;
   p.KeepUnmatched = true;
   p.FunctionName = 'EventProcess plot method';
   p.addParameter('handle',[],@(x) isnumeric(x) || ishandle(x));
   p.addParameter('overlay',false);
   p.parse(varargin{:});
   par = p.Results;

   if isempty(par.handle) || ~ishandle(par.handle)
      figure;
      h = subplot(1,1,1);
   else
      h = par.handle;
   end
   hold on;
   xlim = get(h,'xlim');
   ylim = get(h,'ylim');
   
   gui.h = h;
   set(h,'tickdir','out','ticklength',[0.005 0.025]);

   if numel(self) > 1
      gui.arraySlider = uicontrol('Style','slider','Min',1,'Max',numel(self),...
         'SliderStep',[1 5]./numel(self),'Value',1,...
         'Units','norm','Position',[0.01 0.005 .2 .05],...
         'Parent',h.Parent,'Tag','ArraySlider');
      gui.arraySliderTxt = uicontrol('Style','text','String','Element 1/',...
         'HorizontalAlignment','left','Units','norm','Position',[.22 .005 .2 .05]);
      set(gui.arraySlider,'Callback',{@updatePlot self gui});
   end
   
   menu = uicontextmenu();
   % Create top-level menu item
   topmenu = uimenu('Parent',menu,'Label','Add event');
   validEventTypes = {'Generic' 'Artifact' 'Stimulus' 'Response'};
   for i = 1:numel(validEventTypes)
      uimenu('Parent',topmenu,'Label',validEventTypes{i},'Callback',{@addEvent self gui validEventTypes{i}});
   end
   set(h,'uicontextmenu',menu);

%    values = self.values{1};
%    for i = 1:numel(values)
%       if par.overlay
%          plotEvent(values(i),self,h,ylim(2),ylim(1),0.15);
%       else
%          d = 0.07*diff(ylim);
%          d2 = (d/numel(values));
%          plotEvent(values(i),self,h,ylim(2)+d2*i,ylim(2)+d2*(i-1),0.4);
%          axis([xlim  ylim(1) ylim(2)+d]);
%       end
%    end
   
   % First draw
   refreshPlot(self,gui);

   if nargout >= 1
      varargout{1} = h;
   end
end

function updatePlot(~,~,obj,gui)
   refreshPlot(obj,gui);
end

function refreshPlot(obj,gui)
   if numel(obj) > 1
      ind1 = min(max(1,round(gui.arraySlider.Value)),numel(obj));
   else
      ind1 = 1;
   end
   values = obj(ind1).values{1};
   %t = obj(ind1).times{1};
   
   n = numel(values);
   
   bottom = 0;
   top = 1;
   alpha = 0.15;
   
   h = gui.h;
   ph = findobj(h,'Tag','Event');
   
   % Do we need to draw from scratch, or can we replace data in handles?
   if isempty(ph)
      newdraw = true;
   elseif numel([values.name]) ~= numel([ph.UserData])
      newdraw = true;
   else
      [bool,ind] = ismember([values.name],[ph.UserData]);
      newdraw = any(~bool);
   end
   
   if newdraw
      delete(findobj(h,'Tag','Event')); clear ph;
      for i = 1:n
         try
            color = values(i).name.color;
         catch
            color = [0 0 0];
         end
         
         left = values(i).time(1);
         right = values(i).time(2);
         ph(i) = fill([left left right right],[bottom top top bottom],...
            color,'FaceAlpha',alpha,'EdgeColor','none','Parent',h);
         set(ph(i),'UserData',values(i).name,'Tag','Event');
         if values(i).duration == 0
            ph(i).EdgeColor = color;
         end
      end
   else
      % Ensure that patch handles are ordered like data
      ph = ph(ind);
      for i = 1:n
         left = values(i).time(1);
         right = values(i).time(2);
         ph(i).Vertices = [[left left right right]' [bottom top top bottom]'];
      end
   end
      
   % Attach menus
   if newdraw
      delete(findobj(h.Parent,'Tag','Menu'));
      eventMenu = uicontextmenu();
      m1 = uimenu('Parent',eventMenu,'Label','Edit','Callback',{@editEvent obj(ind1)});
      m2 = uimenu('Parent',eventMenu,'Label','Move','Callback',{@moveEvent obj(ind1) h});
      m3 = uimenu('Parent',eventMenu,'Label','Delete','Callback',{@deleteEvent obj(ind1) h});
      m4 = uimenu('Parent',eventMenu,'Label','Change color','Callback',{@pickColor obj(ind1) h});
      set(eventMenu,'Tag','Menu');
      %set([m1 m2 m3 m4],'UserData',event.name,'Tag','Event');
      set(ph,'uicontextmenu',eventMenu);
   end
   
   % Refresh labels
   if newdraw
      delete(findobj(h,'Tag','TextLabel'));
      for i = 1:n
         try
            color = values(i).name.color;
         catch
            color = [0 0 0];
         end
         try
            name = values(i).name.name;
         catch
            name = values(i).name;
         end
         
         left = values(i).time(1);
         eText = text(left,top,name,'VerticalAlignment','bottom',...
            'FontAngle','italic','Color',color,'Parent',h);
         set(eText,'UserData',values(i).name,'Tag','TextLabel');
      end
      axis tight;
   else
      th = findobj(h,'Tag','TextLabel');
      th = th(ind);
      for i = 1:n
         th(i).Position(1) = values(i).time(1);
      end
   end
end

% function plotEvent(event,obj,h,top,bottom,alpha)
%    left = event.time(1);
%    right = event.time(2);
% 
%    eventMenu = uicontextmenu();
%    m1 = uimenu('Parent',eventMenu,'Label','Edit','Callback',{@editEvent obj});
%    m2 = uimenu('Parent',eventMenu,'Label','Move','Callback',{@moveEvent obj h});
%    m3 = uimenu('Parent',eventMenu,'Label','Delete','Callback',{@deleteEvent obj h});
%    m4 = uimenu('Parent',eventMenu,'Label','Change color','Callback',{@pickColor obj h});
%    set([m1 m2 m3 m4],'UserData',event.name,'Tag','Event');
% 
%    try
%       color = event.name.color;
%    catch
%       color = [0 0 0];
%    end
%    
%    if event.duration == 0
%       eGraphic = line([left left],[bottom top],'Color',color,'Linewidth',2,'Parent',h);
%       set(eGraphic,'UserData',event.name,'Tag','Event'); % Store event name 
%       set(eGraphic,'uicontextmenu',eventMenu);
%    else
%       eGraphic = fill([left left right right],[bottom top top bottom],...
%          color,'FaceAlpha',alpha,'EdgeColor','none','Parent',h);
%       set(eGraphic,'UserData',event.name,'Tag','Event');
%       set(eGraphic,'uicontextmenu',eventMenu);
%    end
%    
%    try
%       name = event.name.name;
%    catch
%       name = event.name;
%    end
%        
%    eText = text(left,top,name,'VerticalAlignment','bottom',...
%       'FontAngle','italic','Color',color,'Parent',h);
%    set(eText,'UserData',event.name,'Tag','Event');
% end

% function setLabels(h,label)
%    th = findall(h,'Tag','Event','Type','Text');
%    ind = find([th.UserData]==label);
%    for i = ind
%       th(i).String = th(i).UserData.name;
%       th(i).Color = th(i).UserData.color;
%    end
% end

function addEvent(~,~,obj,gui,eventType)
   if numel(obj) > 1
      ind1 = min(max(1,round(gui.arraySlider.Value)),numel(obj));
   else
      ind1 = 1;
   end
   
   d = dragRect('xx');
   g = ancestor(gui.h,'Figure');
   set(g,'WindowKeyPressFcn',{@keypressEvent});
   
   function keypressEvent(~,~)
      name = inputdlg('Event name:','Event name');
      event = metadata.event.(eventType)('name',metadata.Label('name',name{1}));
      if d.xPoints(1) <= d.xPoints(2)
         event.tStart = d.xPoints(1);
         event.tEnd = d.xPoints(2);
      else
         event.tStart = d.xPoints(2);
         event.tEnd = d.xPoints(1);
      end
      obj(ind1).insert(event);
      refreshPlot(obj,gui);
      delete(d);
      set(g,'WindowKeyPressFcn','');
   end
end

function editEvent(source,~,obj)
	event = find(obj,'eventProp','name','eventVal',source.UserData);
   propertiesGUI(event);
end

function moveEvent(source,~,obj,h)
%keyboard
%    p = findobj(h,'UserData',source.UserData,'-and','Type','patch');
%    if isempty(p)
%       p = findobj(h,'UserData',source.UserData,'-and','Type','line');
%    end
   p = gco;
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
keyboard
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

function deleteEvent(~,~,obj,h)
   ph = gco;  
   obj.remove(ph.Vertices(1,1));
   g = findobj(h,'UserData',ph.UserData);
   delete(g);
end

function pickColor(~,~,obj,h)
   ph = gco;
   event = find(obj,'eventProp','name','eventVal',ph.UserData);
   
   try
      color = event.name.color;
   catch
      error('EventProcess:plot','Event names do not have color properties');
   end

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
