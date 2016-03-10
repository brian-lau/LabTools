% PLOT - Plot SampledProcess
%
%     plot(SampledProcess)
%     SampledProcess.plot
%
%     Right clicking (ctrl-clicking) any line allows editing the quality,
%     color and label associated with that line.
%
%     For an array of SampledProcesses, a horizontal scrollbar in the
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
%     hh     - Axis handle
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
function hh = plot(self,varargin)

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
   
   sep_min = 0;
   sd = nanstd(self(1).values{1}(:));
   sep_max = 30*sd;
   if par.stack
      sep_init = par.sep*sd;
   else
      sep_init = 0;
   end
   
   % Create the sep slider
   sepSlider = javax.swing.JSlider(javax.swing.JSlider.VERTICAL,sep_min,sep_max,sep_init);
   [jsepSlider,hsepSlider] = javacomponent(sepSlider,[0,20,30,200],h.Parent);
   set(hsepSlider,'UserData',jsepSlider,'Tag','SepSlider',...
      'Units','norm','Position',[0 .25 .05 .5]);
   hjSlider = handle(sepSlider,'CallbackProperties');
   hjSlider.StateChangedCallback = {@updatePlot self gui};

   % First draw
   refreshLines(self,gui);
   
   if nargout
      hh = h;
   end
end

function updatePlot(~,~,obj,gui)
   refreshLines(obj,gui);
end

function refreshLines(obj,gui)
   if numel(obj) > 1
      ind1 = min(max(1,round(gui.arraySlider.Value)),numel(obj));
   else
      ind1 = 1;
   end
   values = obj(ind1).values{1};
   t = obj(ind1).times{1};
   
   hsepSlider = findobj(gui.h.Parent,'tag','SepSlider');
   sep = hsepSlider.UserData.getValue();

   n = size(values,2);
   sd = nanstd(obj(ind1).values{1}(:));
   
   hsepSlider.UserData.setMaximum(30*sd);
   
   sf = (0:n-1)*sep; % shift factor
   h = gui.h;
   lh = findobj(h,'Tag','Line');
   
   % Do we need to draw from scratch, or can we replace data in handles?
   if isempty(lh)
      newdraw = true;
   else
      [bool,ind] = ismember(obj(ind1).labels,[lh.UserData]);
      newdraw = all(~bool);
   end
   
   if newdraw
       % Need to draw lines
      delete(findobj(h,'Tag','Line'));
      if sep > 0
         n = size(values,2);
         sf = (0:n-1)*sep;
         lh = plot(t,bsxfun(@plus,values,sf),'Parent',h);
         % Plot zero level for each line
         plot(repmat([t(1) t(end)]',1,n),[sf' , sf']',...
            '--','color',[.7 .7 .7 .4],'Parent',h,'Tag','BaseLine');
      else
         lh = plot(t,values,'Parent',h);
      end
      % Store the label for each line
      for i= 1:numel(lh)
         set(lh(i),'UserData',obj(ind1).labels(i),'Tag','Line');
      end
      % Distribute label colors, masking for quality=0
      q0 = obj(ind1).quality == 0;
      [lh(~q0).Color] = deal(obj(ind1).labels(~q0).color);
      [lh(q0).Color] = deal([.7 .7 .7 .4]);
   else
      % Ensure that line handles are ordered like data
      %[bool,ind] = ismember([lh.UserData],obj(ind1).labels);
      lh = lh(ind);
      
      % Refresh data for each line
      data = bsxfun(@plus,values,sf);
      for i = 1:n
         lh(i).YData = data(:,i);
      end
   end
   
   % Refresh zero level for each line
   if newdraw
      delete(findobj(h,'Tag','BaseLine'));
      % Plot zero level for each line
      plot(repmat([t(1) t(end)]',1,n),[sf' , sf']',...
         '--','color',[.7 .7 .7 .4],'Parent',h,'Tag','BaseLine');
   else
      blh = findobj(h,'Tag','BaseLine');
      for i = 1:n
         blh(i).YData = [sf(i) sf(i)];
      end
   end
   
   % Attach menus
   if newdraw
      delete(findobj(h.Parent,'Tag','Menu'));
      lineMenu = uicontextmenu();
      uimenu(lineMenu,'Label','Quick set quality = 0','Callback',{@setQuality obj(ind1) 0});
      uimenu(lineMenu,'Label','Edit quality','Callback',{@setQuality obj(ind1) NaN});
      uimenu(lineMenu,'Label','Change color','Callback',{@pickColor obj(ind1) h});
      uimenu(lineMenu,'Label','Edit label','Callback',{@editLabel obj(ind1) h});
      set(lineMenu,'Tag','Menu');
      set(lh,'uicontextmenu',lineMenu);
   end
   
   % Refresh labels
   if newdraw
      delete(findobj(h,'Tag','TextLabel'));
      setLabels(gui.h);
      axis tight;
   else
      th = findobj(h,'Tag','TextLabel');
      for i = 1:n
         th(i).Position(2) = (max(lh(i).YData) + min(lh(i).YData))/2;
      end
   end
   
   gui.arraySliderTxt.String = ['element ' num2str(ind1) '/' num2str(numel(obj))];
   h.YTick = [0 1*sd 2*sd 3*sd];
   set(h,'yticklabel',{'0' sprintf('%1.2f (1 SD)',sd) sprintf('%1.2f (2 SD)',2*sd) sprintf('%1.2f (3 SD)',3*sd)});
end

function setLabels(h,label)
   right = h.XLim(2);
   lh = findobj(h,'Tag','Line');
   if nargin < 2
      for i = 1:numel(lh)
         y = (max(lh(i).YData) + min(lh(i).YData))/2;
         text(right,y,lh(i).UserData.name,'VerticalAlignment','middle',...
            'FontAngle','italic','Color',lh(i).UserData.color,...
            'UserData',lh(i).UserData,'Tag','TextLabel','Parent',h);
      end
   else
      th = findobj(h,'Tag','TextLabel');
      ind = find([th.UserData]==label);
      for i = ind
         th(i).String = th(i).UserData.name;
         th(i).Color = th(i).UserData.color;
      end
   end
end

function setQuality(~,~,obj,quality)
   lh = gco;
   label = lh.UserData;
   ind = obj.labels == label;
   if isnan(quality)
      mouse = get(0,'PointerLocation');
      d = dialog('Position',[mouse 200 150],'Name','Set quality');
      uicontrol(d,'Style','edit','Callback',{@txtcallback obj},...
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
            lh.Color = [.7 .7 .7 .4];
         else
            lh.Color = obj.labels(ind).color;
         end
      end
   end
end

function txtcallback(data,~,obj)
   h = findobj(data.Parent,'Style','edit');
   
   quality = str2double(h.String);
   delete(h.Parent);
   
   setQuality([],[],obj,quality);
end

function pickColor(~,~,obj,h)
   lh = gco;
   label = lh.UserData;
   ind = obj.labels == label;
   
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
      lh.Color = obj.labels(ind).color;
   end
   
   % Redraw labels
   setLabels(h,label);
end

function editLabel(~,~,obj,h)
   lh = gco;
   label = lh.UserData;
   %TODO
end
