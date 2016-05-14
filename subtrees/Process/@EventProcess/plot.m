% PLOT - Plot EventProcess
%
%     plot(EventProcess)
%     EventProcess.plot
%
%     Right clicking (ctrl-clicking) on events displays options for moving or
%     deleting events. Right clicking outside of events allows adding events.
%
%     For an array of EventProcesses, a horizontal scrollbar at the bottom
%     left allows browsing through the array elements.
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% INPUTS
%     handle  - axis handle, optional, default generates a new axis
%     top     - scalar, optional, default = []
%               Sets the upper limit of patches, if empty, Ylim of axes used
%     bottom  - scalar, optional, default = []
%               Sets the lower limit of patches, if empty, Ylim of axes used
%     overlap - scalar, optional, default = 1
%               Value [-1 1] that determines fraction of the axes patches 
%               will cover. 1 covers from top to bottom. Negative numbers
%               extend the Ylim above top.
%     stagger - logical, optional, default = false
%               If true, events are offset vertically so they do not cover
%               each other
%     alpha   - scalar, optional, default = 0.2
%               Value [0 1] the determines alpha transparency of patches
%
% OUTPUTS
%     h      - Axis handle
%
% EXAMPLES
%     % Create labels for the events (necessary if you want to edit color)
%     fix = metadata.Label('name','fix');
%     cue = metadata.Label('name','cue');
%     button = metadata.Label('name','button');
%     % Create EventProcess array
%     for i = 1:50
%        t = rand;
%        e(1) = metadata.event.Stimulus('tStart',t,'tEnd',t+1,'name',fix);
%        t = 2 + rand;
%        e(2) = metadata.event.Stimulus('tStart',t,'tEnd',t,'name',cue);
%        t = 4 + rand;
%        e(3) = metadata.event.Response('tStart',t,'tEnd',t+.2,'name',button,'experiment',metadata.Experiment);
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
   p.addParameter('alpha',0.2,@isnumeric);
   p.addParameter('stagger',false,@(x) isnumeric(x) || islogical(x) );
   p.addParameter('overlap',1,@(x) isnumeric(x) || islogical(x) );
   p.addParameter('patchcallback','');
   p.parse(varargin{:});
   par = p.Results;

   if isempty(par.handle) || ~ishandle(par.handle)
      figure;
      h = subplot(1,1,1);
   else
      h = par.handle;
   end
   hold(h,'on');
   set(h,'tickdir','out','ticklength',[0.005 0.025],'Visible','off');

   % Unique ID to tag objects from this call
   gui.id = char(java.util.UUID.randomUUID.toString);

   gui.alpha = par.alpha;   
   gui.bottom = par.bottom;
   gui.top = par.top;
   gui.overlap = par.overlap;
   gui.stagger = par.stagger;
   gui.patchcallback = par.patchcallback;
   
   if numel(self) > 1
      ah = findobj(h.Parent,'Tag','ArraySlider');
      if isempty(ah)
         gui.arraySlider = uicontrol('Style','slider','Min',1,'Max',numel(self),...
            'SliderStep',[1 5]./numel(self),'Value',1,...
            'Units','norm','Position',[0.01 0.005 .2 .04],...
            'Parent',h.Parent,'Tag','ArraySlider');
         gui.arraySliderTxt = uicontrol('Style','text','String','Element 1/',...
            'HorizontalAlignment','left','Units','norm','Position',[.22 .005 .2 .04]);
         % Use cellfun in the callback to allow adding multiple callbacks later
         set(gui.arraySlider,'Callback',...
            {@(h,e,x) cellfun(@(x)feval(x{:}),x) {{@refreshPlot self h gui.id}} } );
      else
         % Adding event plot to existing axis that has slider controls
         % Attach callbacks to existing list, to be evaluated in sequence
         gui.arraySlider = ah;
         f = {@refreshPlot self h gui.id};
         ah.Callback{2}{end+1} = f;
      end
   end

   % This slider will be present if handle comes from SampledProcess.plot,
   % in which case, we link a callback to refresh events 
   sh = findobj(h.Parent,'Tag','LineScaleSlider');
   if ~isempty(sh)
      f = {@refreshPlot self h gui.id};
      sh.UserData.StateChangedCallback{2}{end+1} = f;
   end
   
   % Stash plot-specific parameters
   if isempty(h.UserData)
      h.UserData = {gui};
   else
      h.UserData = [h.UserData {gui}];
   end
   
   hf = ancestor(h,'Figure');

   % Create top-level menu for Events
   menu = uicontextmenu('Tag',gui.id,'Parent',hf);
   topmenu = uimenu('Parent',menu,'Label','Add event');
   validEventTypes = {'Artifact' 'Stimulus' 'Response' 'Generic'};
   for i = 1:numel(validEventTypes)
      uimenu('Parent',topmenu,'Label',validEventTypes{i},...
         'Callback',{@addEvent self h gui.id validEventTypes{i}});
   end
   set(h,'uicontextmenu',menu);
   
   % First draw
   refreshPlot(self,h,gui.id);
   h.Visible = 'on';

   if nargout >= 1
      varargout{1} = h;
   end
end

function refreshPlot(obj,h,id)
   % Extract specific parameters for this ID
   gui = linq(h.UserData).where(@(x) strcmp(x.id,id)).select(@(x) x).toArray;

   if numel(obj) > 1
      ind1 = max(1,round(gui.arraySlider.Value));
   else
      ind1 = 1;
   end
   
   if ind1 > numel(obj)
      delete(findobj(h,'Tag',id));
      return;
   end
   
   if obj(ind1).count == 0
      delete(findobj(h,'Tag',id,'-and','Type','Patch'));
      delete(findobj(h,'Tag',id,'-and','Type','Text'));
      return;
   end
   values = obj(ind1).values{1};
   n = numel(values);
   
   if isempty(gui.bottom)
      bottom = h.YLim(1);
   else
      bottom = gui.bottom;
   end
   if isempty(gui.top)
      top = h.YLim(2);
   else
      top = gui.top;
   end
   
   d = (top - bottom)*(1-gui.overlap);
   if d < 0
      bottom = top;
      top = top - d;
   else
      bottom = bottom + d;
   end
   
   step = (top - bottom)/n;
      
   ph = findobj(h,'Tag',id,'-and','Type','Patch');
   
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
      delete(findobj(h,'Tag',id,'-and','Type','Patch')); clear ph;
      for i = 1:n
         try
            color = values(i).name.color;
         catch
            color = [0 0 0];
         end
         
         left = values(i).time(1);
         right = values(i).time(2);
         
         if gui.stagger
            topbottom = bottom + [(i-1)*step i*step i*step (i-1)*step];
         else
            topbottom = [bottom top top bottom];
         end
         ph(i) = fill([left left right right],topbottom,...
            color,'FaceAlpha',gui.alpha,'EdgeColor','none','Parent',h);
         set(ph(i),'UserData',values(i).name,'Tag',id,'ButtonDownFcn',gui.patchcallback);
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
         
         if gui.stagger
            topbottom = bottom + [(i-1)*step i*step i*step (i-1)*step];
         else
            topbottom = [bottom top top bottom];
         end
         
         ph(i).Vertices = [[left left right right]' topbottom'];
      end
   end
      
   hf = ancestor(h,'Figure');

   % Attach menus
   %if newdraw
      delete(findobj(h.Parent,'Tag',id,'-and','Type','ContextMenu'));
      eventMenu = uicontextmenu('Parent',hf,'Callback',@patchHittest);
      uimenu('Parent',eventMenu,'Label','Move','Callback',{@moveEvent obj(ind1) h});
      uimenu('Parent',eventMenu,'Label','Delete','Callback',{@deleteEvent obj(ind1) h});
      uimenu('Parent',eventMenu,'Label','Change color','Callback',{@pickColor obj(ind1) h});
      uimenu('Parent',eventMenu,'Label','View properties','Callback',{@editEvent obj(ind1)});
      set(eventMenu,'Tag',id);
      set(ph,'uicontextmenu',eventMenu);
   %end
   
   % Refresh labels
   if newdraw
      delete(findobj(h,'Tag',id,'-and','Type','Text'));
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
         
         if gui.stagger
            top2 = bottom + (i)*step;
         else
            top2 = top;
         end
         
         left = values(i).time(1);
         eText = text(left,top2,name,'VerticalAlignment','bottom',...
            'FontAngle','italic','Color',color,'Parent',h);
         set(eText,'UserData',values(i).name,'Tag',id);
      end
      axis(h,'tight');
   else
      th = findobj(h,'Tag',id,'-and','Type','Text');
      th = th(ind);
      for i = 1:n
         if gui.stagger
            top2 = bottom + (i)*step;
         else
            top2 = top;
         end
         th(i).Position(1) = values(i).time(1);
         th(i).Position(2) = top2;
      end
   end
   
   if gui.overlap < 0
      h.YLim(2) = top + abs((top - bottom)*(1-gui.overlap));
   end
   
   gui.arraySliderTxt.String = ['element ' num2str(ind1) '/' num2str(numel(obj))];
end

function addEvent(~,~,obj,h,id,eventType)
   % Extract specific parameters for this ID
   gui = linq(h.UserData).where(@(x) strcmp(x.id,id)).select(@(x) x).toArray;

   if numel(obj) > 1
      ind1 = min(max(1,round(gui.arraySlider.Value)),numel(obj));
   else
      ind1 = 1;
   end
   
   d = dragRect('xx',[],h);
   g = ancestor(h,'Figure');
   orig = g.WindowKeyPressFcn;
   g.WindowKeyPressFcn = {@keypressEvent};
   
   function keypressEvent(~,~)
      name = inputdlg('Event name:','Event name');
      if isempty(name) % Cancel or no name given
         delete(d);
         g.WindowKeyPressFcn = orig;
         return;
      end
      event = metadata.event.(eventType)('name',metadata.Label('name',name{1}));
      if d.xPoints(1) <= d.xPoints(2)
         event.tStart = d.xPoints(1);
         event.tEnd = d.xPoints(2);
      else
         event.tStart = d.xPoints(2);
         event.tEnd = d.xPoints(1);
      end
      if isa(event,'metadata.event.Artifact')
         p = findobj(h,'Type','Text','-not','Tag',id);
         labels = [p.UserData]; %fliplr([p.UserData]);
         
         [s,v] = listdlg('PromptString','Channels to which event applies',...
            'SelectionMode','multiple','ListString',{labels.name});
         if v
            event.labels = labels(s);
         end
      end
      
      obj(ind1).insert(event);
      refreshPlot(obj,h,id);
      delete(d);
      g.WindowKeyPressFcn = orig;
   end

end

function editEvent(src,~,obj)
   ph = src.Parent.UserData;
   ind = [obj.values{1}.name] == ph.UserData;
   label = ph.UserData;
   event = obj.values{1}(ind);	
   warning('OFF','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
   [h,event] = propertiesGUI(event);
   warning('ON','MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
end

function moveEvent(src,~,obj,h)
   ph = src.Parent.UserData;
   ind = [obj.values{1}.name] == ph.UserData;
   label = ph.UserData;
   event = obj.values{1}(ind);
   textLabel = findobj(h,'UserData',ph.UserData,'-and','Type','Text');
   % findobj matches structs, so we need to restrict to handle matches
   ind2 = [textLabel.UserData] == label;
   textLabel(~ind2) = [];
   
   setptr(ancestor(h,'Figure'),'hand');
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

function deleteEvent(src,~,obj,h)
   ph = src.Parent.UserData;
   obj.remove(ph.Vertices(1,1));
   g = findobj(h,'UserData',ph.UserData);
   delete(g);
end

function pickColor(src,~,obj,h)
   ph = src.Parent.UserData;
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

function patchHittest(src,~)
   src.UserData = hittest(ancestor(src,'figure'));
end