% PLOT - Plot SampledProcess
%
%     plot(SampledProcess)
%     SampledProcess.plot
%
%     Right clicking (ctrl-clicking) any line allows editing the quality,
%     color and label associated with that line.
%
%     A double slider at the bottom right controls the range of data 
%     displayed (0-100% of the relative window of each SampledProcess).
%     The left and right edges can be adjusted indepdendently, and
%     click-dragging in between the two knobs moves the entire range.
%     Double clicking in between the two knobs resets the range.
%
%     For an array of SampledProcesses, a horizontal slider at the bottom
%     left allows browsing through the array elements. The vertical scrollbar
%     allows controlling vertical spacing between channels.
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
%     %SampledProcess array where each element has channels with the same labels
%     s = SampledProcess(randn(20,20)+5*eye(20));
%     l = s.labels;
%     for i = 2:50
%        s(i) = SampledProcess(randn(20,20)+5*eye(20),'labels',l);
%     end
%     plot(s);

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process

% TODO
% o multiple windows
% o edit label
% o use zoom ActionPostCallback to change label positions
function varargout = plot(self,varargin)
   p = inputParser;
   p.KeepUnmatched = true;
   p.FunctionName = 'SampledProcess plot method';
   p.addParameter('handle',[],@(x) isnumeric(x) || ishandle(x));
   p.addParameter('stack',true,@(x) isnumeric(x) || islogical(x));
   p.addParameter('sep',3,@(x) isscalar(x));
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
   
   gui.lineScaleSliderDiv = 3; % Slider stops per SD
   gui.lineScaleSliderNSD = 9; % # of signal SDs to cover
   sd = nanstd(self(1).values{1}(:));
   gui.lineScaleSliderSD = sd;
   
   sh = findobj(h.Parent,'Tag','LineScaleSlider');
   if isempty(sh)
      sep_min = 0;
      sep_max = gui.lineScaleSliderDiv*gui.lineScaleSliderNSD;
      if par.stack
         sep_init = par.sep*gui.lineScaleSliderDiv;
      else
         sep_init = 0;
      end
      % Create the slider controlling separation between lines
      sepSlider = javax.swing.JSlider(javax.swing.JSlider.VERTICAL,...
         sep_min,sep_max,sep_init);
      [jsepSlider,hsepSlider] = javacomponent(sepSlider,[0 0 1 1],h.Parent);
      set(hsepSlider,'UserData',jsepSlider,'Tag','LineScaleSlider',...
         'Units','norm','Position',[0 .25 .04 .5],'Parent',h.Parent);
      % Use cellfun in the callback to allow adding multiple callbacks later
      jsepSlider.StateChangedCallback = ...
         {@(h,e,x) cellfun(@(x)feval(x{:}),x) {{@refreshPlot self h gui.id hsepSlider}} };
   else
      % Adding event plot to existing axis that has slider controls
      % Attach callbacks to existing list, to be evaluated in sequence
      hsepSlider = findobj(h.Parent.Children,'flat','tag','LineScaleSlider');
      f = {@refreshPlot self h gui.id hsepSlider};
      sh.UserData.StateChangedCallback{2}{end+1} = f;
   end
   
   if numel(self) > 1
      ah = findobj(h.Parent,'Tag','ArraySlider');
      if isempty(ah)
         gui.arraySlider = uicontrol('Style','slider','Min',1,'Max',numel(self),...
            'SliderStep',[1 5]./numel(self),'Value',1,...
            'Units','norm','Position',[0.01 0.005 .2 .04],...
            'Parent',h.Parent,'Tag','ArraySlider');
         gui.arraySliderTxt = uicontrol('Style','text','String','Element 1/',...
            'HorizontalAlignment','left','Parent',h.Parent,...
            'Units','norm','Position',[.22 .005 .2 .04],'Tag','ArraySliderTxt');
         % Use cellfun in the callback to allow adding multiple callbacks later
         set(gui.arraySlider,'Callback',...
            {@(h,e,x) cellfun(@(x)feval(x{:}),x) {{@refreshPlot self h gui.id hsepSlider}} } );
      else
         % Adding event plot to existing axis that has slider controls
         % Attach callbacks to existing list, to be evaluated in sequence
         gui.arraySlider = ah;
         f = {@refreshPlot self h gui.id hsepSlider};
         ah.Callback{2}{end+1} = f;
      end
   end

   % Set up slider to control time range
   % This slider will be present if handle comes from SampledProcess.plot.
   % If so, let the originating process control the time range, otherwise add
   rh = findobj(h.Parent,'Tag','RangeSlider');
   if isempty(rh)
      rangeSlider = com.jidesoft.swing.RangeSlider(0,150,0,150);  % min,max,low,high
      [rangeSlider,hrangeSlider] = javacomponent(rangeSlider,[0 0 1 1],h.Parent);
      set(hrangeSlider,'UserData',rangeSlider,'Tag','RangeSlider',...
         'Units','norm','Position',[.4 .005 .525 .05],'Parent',h.Parent);
      set(rangeSlider,'Enabled',false,'StateChangedCallback',{@setx self h gui.id});
   end
   
   % Stash plot-specific parameters
   if isempty(h.UserData)
      h.UserData = {gui};
   else
      h.UserData = [h.UserData {gui}];
   end
   
   % First draw
   refreshPlot(self,h,gui.id,hsepSlider);
   h.Visible = 'on';
   
   if nargout >= 1
      varargout{1} = h;
   end
end

%%
function setx(e,~,obj,h,id)
   % Extract specific parameters for this ID
   gui = linq(h.UserData).where(@(x) strcmp(x.id,id)).select(@(x) x).toArray;

   if numel(obj) > 1
      ind1 = max(1,round(gui.arraySlider.Value));
   else
      ind1 = 1;
   end
   
   minmaxwin = obj(ind1).relWindow;
   d = minmaxwin(2) - minmaxwin(1);  

   lo = minmaxwin(1) + e.getLowValue*d/150;
   hi = minmaxwin(1) + e.getHighValue*d/150 + 100*eps(h.XLim(1));
   
   % Set the xlimits of axis
   ah = findobj(h.Parent.Children,'flat','Type','Axes');
   try
      set(ah,'XLim',[lo hi]);
   catch err
      if strcmp('MATLAB:hg:shaped_arrays:LimitsWithInfsPredicate',err.identifier)
         set(ah,'XLim',[hi lo]);
      else
         rethrow(err);
      end
   end

   % Move the text labels
   th = findobj(h.Children,'flat','Tag',id,'-and','Type','Text');
   for i = 1:numel(th)
      th(i).Position(1) = h.XLim(2);
   end
end

function refreshPlot(obj,h,id,hsepSlider)
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
   
   values = obj(ind1).values{1};
   t = obj(ind1).times{1};
   % Convert slider step to data scale
   sep = hsepSlider.UserData.Value*gui.lineScaleSliderSD/gui.lineScaleSliderDiv;

   n = size(values,2);
   %hsepSlider.UserData.setMaximum(9*sd*10); % THIS TRIGGERS CALLBACK
   
   sf = (0:n-1)*sep; % shift factor
   lh = findobj(h.Children,'flat','Tag',id,'-and','Type','Line','-and','LineStyle','-');
   %lh = findobj(h.Children,'flat','Tag',id,'-and','-and','Type','Line','LineStyle','-');
   
   % Do we need to draw from scratch, or can we replace data in handles?
   if isempty(lh)
      newdraw = true;
   else
      [bool,ind] = ismember(obj(ind1).labels,[lh.UserData]);
      newdraw = any(~bool);
   end
      
   % Draw lines
   if newdraw
      delete(findobj(h,'flat','Tag',id,'-and','Type','Line'));
      if sep > 0
         n = size(values,2);
         sf = (0:n-1)*sep;
         lh = plot(t,bsxfun(@plus,values,sf),'Parent',h);
      else
         lh = plot(t,values,'Parent',h);
      end
      % Store the label for each line
      for i= 1:numel(lh)
         set(lh(i),'UserData',obj(ind1).labels(i),'Tag',id);
      end
   else
      % Ensure that line handles are ordered like data
      lh = lh(ind);
      % Refresh data for each line
      data = bsxfun(@plus,values,sf);
      set(lh,'XData',t);
      for i = 1:n
         lh(i).YData = data(:,i);
      end
   end
   
   % Distribute label colors to lines, masking for quality=0
   q0 = obj(ind1).quality == 0;
   if any(q0)
      [lh(~q0).Color] = deal(obj(ind1).labels(~q0).color);
      [lh(q0).Color] = deal([.7 .7 .7 .4]);
   elseif all(q0)
      [lh(q0).Color] = deal([.7 .7 .7 .4]);
   else
      try
         [lh(~q0).Color] = deal(obj(ind1).labels(~q0).color);
      catch
         [lh(~q0).Color] = deal([0.2 0.2 0.2]);
      end
   end
   
   % Draw zero level for each line
   if newdraw
      temp = [sf; sf; nan(size(sf))]; % Draw as single line
      plot(repmat([t(1) t(end) NaN]',n,1),temp(:),...
         '--','color',[.7 .7 .7 .4],'Parent',h,'Tag',id);
   else
      blh = findobj(h.Children,'flat','Tag',id,'-and','LineStyle','--');
      temp = [sf; sf; nan(size(sf))];
      blh.YData = temp(:)';
   end
   
   hf = ancestor(h,'Figure');
   
   % Attach menus
   delete(findobj(h.Parent.Children,'flat','Tag',id,'-and','Type','uicontextmenu'));
   lineMenu = uicontextmenu('Parent',hf,'Callback',@lineHittest);
   uimenu(lineMenu,'Label','Quick set quality = 0','Callback',{@setQuality obj(ind1) 0});
   uimenu(lineMenu,'Label','Edit quality','Callback',{@setQuality obj(ind1) NaN});
   uimenu(lineMenu,'Label','Change color','Callback',{@pickColor obj(ind1) h});
   uimenu(lineMenu,'Label','Edit label','Callback',{@editLabel obj(ind1) h});
   set(lineMenu,'Tag',id);
   set(lh,'uicontextmenu',lineMenu);
   
   % Refresh labels
   if newdraw
      delete(findobj(h,'Tag',id,'-and','Type','Text'));
      for i = 1:n
         if isempty(lh(i).UserData.color)
            text(t(end),sf(i),lh(i).UserData.name,'VerticalAlignment','middle',...
               'FontAngle','italic','Color',[.2 .2 .2],...
               'UserData',lh(i).UserData,'Tag',id,'Parent',h);
         else
            text(t(end),sf(i),lh(i).UserData.name,'VerticalAlignment','middle',...
               'FontAngle','italic','Color',lh(i).UserData.color,...
               'UserData',lh(i).UserData,'Tag',id,'Parent',h);
         end
      end
   else
      th = findobj(h.Children,'flat','Tag',id,'-and','Type','Text');
      th = th(ind);
      for i = 1:n
         th(i).Position = [t(end) sf(i)];
      end
   end
   
   if isempty(hf.KeyPressFcn)%isempty(h.Parent.KeyPressFcn) % Zoom is not active
      rh = findobj(h.Parent.Children,'flat','Tag','RangeSlider');
      if ~rh.UserData.Enabled
         h.XLim(1) = t(1);
         h.XLim(2) = t(end);
         rh.UserData.Enabled = true;
      end
      h.YLim(1) = sf(1)-abs(min(min(values)));
      h.YLim(2) = sf(end)+max(max(values));
   end
   
   gui.arraySliderTxt.String = ['element ' num2str(ind1) '/' num2str(numel(obj))];

   %sd = nanstd(obj(ind1).values{1}(:));
   sd = gui.lineScaleSliderSD; % Use SD from first array element
   h.YTick = [0 1*sd 2*sd 3*sd];
   set(h,'yticklabel',{'0' sprintf('%1.2f (1 SD)',sd) sprintf('%1.2f (2 SD)',2*sd) ...
      sprintf('%1.2f (3 SD)',3*sd)});
end

function setQuality(src,~,obj,quality)
   lh = src.Parent.UserData;
   label = lh.UserData;
   ind = obj.labels == label;
   % Find all corresponding lines in axes in same parent
   lh = findobj(src.Parent.Parent.Children,'Type','line','-and','UserData',label);
   if isnan(quality)
      mouse = get(0,'PointerLocation');
      d = dialog('Position',[mouse 200 150],'Name','Set quality');
      uicontrol(d,'Style','edit','Callback',{@txtcallback obj src},...
         'String',num2str(obj.quality(ind)),'Position',[35 60 130 20]);
      uicontrol(d,'Style','text','Position',[35 80 130 40],...
         'String',{'Enter numeric value for ' label.name});
      uicontrol(d,'String','Accept',...
         'Position',[35 25 130 20],'Callback',{@txtcallback obj});
      uiwait(d);
   else
      if any(ind)
         obj.quality(ind) = quality;
         if quality == 0
            set(lh,'Color',[.7 .7 .7 .4]);
         else
            set(lh,'Color',obj.labels(ind).color);
         end
      end
   end
end

function txtcallback(data,~,obj,src)
   h = findobj(data.Parent,'Style','edit');
   
   quality = str2double(h.String);
   delete(h.Parent);
   
   setQuality(src,[],obj,quality);
end

function pickColor(src,~,obj,h)
   lh = src.Parent.UserData;
   label = lh.UserData;
   ind = obj.labels == label;
   % Find all corresponding lines in axes in same parent
   lh = findobj(src.Parent.Parent.Children,'Type','line','-and','UserData',label);
   
   color = obj.labels(ind).color;
   
   % Set up color dialog
   cc = javax.swing.JColorChooser;
   cp = cc.getChooserPanels;
   cc.setChooserPanels(cp([4 1]));
   cc.setColor(fix(color(1)*255),fix(color(2)*255),fix(color(3)*255));

   mouse = get(0,'PointerLocation');
   d = dialog('Position',[mouse 610 425],'Name','Select color');
   javacomponent(cc,[1,1,610,425],d);
   uiwait(d);
   
   % Set new color
   color = cc.getColor;
   obj.labels(ind).color = [color.getRed color.getGreen color.getBlue]/255;
   if obj.quality(ind) ~= 0
      set(lh,'Color',obj.labels(ind).color);
      %lh.Color = obj.labels(ind).color;
   end

   % Redraw label
   th = findobj(h.Parent.Children,'Type','Text','-and','UserData',label);
   set(th,'Color',obj.labels(ind).color);
end

function editLabel(src,~,obj,h)
   lh = src.Parent.UserData;%gco;
   label = lh.UserData;
   %TODO
   disp('Not Finished');
end

function lineHittest(src,~)
   src.UserData = hittest(ancestor(src,'figure'));
end
