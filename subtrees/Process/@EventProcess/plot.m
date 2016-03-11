% PLOT - Plot EventProcess
%
%     plot(EventProcess)
%     EventProcess.plot
%
%     Right clicking (ctrl-clicking) any line allows editing the quality,
%     color and label associated with that line.
%
%     For an array of EventProcesses, a horizontal scrollbar in the
%     bottom left allows browsing through the array elements.
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% INPUTS
%     handle - axis handle, optional, default generates a new axis
%     stack  - boolean, optional, default = true
%              If true, offsets each channel by an integer multiple of sep.
%     sep    - numeric scalar, optional, default = 3*SD
%              SD is calculated across all channels
%              Slider at left of figure allows changing this
% OUTPUTS
%     h      - Axis handle
%
% EXAMPLES
%     fix = metadata.Label('name','fix');
%     cue = metadata.Label('name','cue');
%     button = metadata.Label('name','button');
%     for i = 1:50
%        t = rand;
%        e(1) = metadata.event.Stimulus('tStart',t,'tEnd',t+1,'name',fix);
%        t = 2 + rand;
%        e(2) = metadata.event.Stimulus('tStart',t,'tEnd',t,'name',cue);
%        t = 4 + rand;
%        e(3) = metadata.event.Response('tStart',t,'tEnd',t+2,'name',button,'experiment',metadata.Experiment);
% 
%        events(i) = EventProcess('events',e);
%     end
%     plot(events)

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process

% TODO
% o multiple windows
function varargout = plot(self,varargin)

   p = inputParser;
   p.KeepUnmatched = true;
   p.FunctionName = 'EventProcess plot method';
   p.addParameter('handle',[],@(x) isnumeric(x) || ishandle(x));
   p.addParameter('top',[],@isnumeric);
   p.addParameter('bottom',[],@isnumeric);
   p.addParameter('alpha',0.15,@isnumeric);
   p.addParameter('stagger',false,@islogical);
   p.parse(varargin{:});
   par = p.Results;

   if isempty(par.handle) || ~ishandle(par.handle)
      figure;
      h = subplot(1,1,1);
   else
      h = par.handle;
   end
   hold(h,'on');
   
   gui.h = h;
   gui.alpha = par.alpha;   
   gui.bottom = par.bottom;
   gui.top = par.top;
   
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
   
   n = numel(values);
   
   if isempty(gui.bottom)
      bottom = h.YLim(1);
   end
   if isempty(gui.top)
      top = h.YLim(2);
   end
%    bottom = gui.bottom;
%    top = gui.top;
   
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
            color,'FaceAlpha',gui.alpha,'EdgeColor','none','Parent',h);
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
      m1 = uimenu('Parent',eventMenu,'Label','View properties','Callback',{@editEvent obj(ind1)});
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
   
   gui.arraySliderTxt.String = ['element ' num2str(ind1) '/' num2str(numel(obj))];
end

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

function editEvent(~,~,obj)
   ph = gco;
   ind = [obj.values{1}.name] == ph.UserData;
   label = ph.UserData;
   event = obj.values{1}(ind);	
   warning('OFF','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
   [h,event] = propertiesGUI(event);
   warning('ON','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
end

function moveEvent(~,~,obj,h)
   ph = gco;
   ind = [obj.values{1}.name] == ph.UserData;
   label = ph.UserData;
   event = obj.values{1}(ind);
   textLabel = findobj(h,'UserData',ph.UserData,'-and','Type','Text');
   
   setptr(gcf,'hand');
   fig.movepatch(ph,'x',@mouseupEvent);

   function mouseupEvent(~,~)
      v = get(ph,'Vertices');
      tStart = v(1,1);
      tEnd = v(3,1);
      event.tStart = tStart;
      event.tEnd = tEnd;
      obj.values{1}(ind) = event;
      obj.times{1}(ind,:) = [tStart tEnd];
      
      textLabel.Position(1) = tStart;
      % HACK - despite nextplot setting, this gets cleared?
      ph.UserData = label;
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
   
   textLabel = findobj(h,'UserData',ph.UserData,'-and','Type','Text');
   textLabel.Color = ph.FaceColor;
end
