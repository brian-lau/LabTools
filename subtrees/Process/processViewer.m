function gui = processViewer(seg)
% Data is shared between all child functions by declaring the variables
% here (all functions are nested). We keep things tidy by putting
% all GUI stuff in one structure and all data stuff in another. As the app
% grows, we might consider making these objects rather than structures.

data = createData(seg);
if data.plotS
   data.sd = getCurrentSD(1);
end
gui = createInterface();

% Now update the GUI with the current data
updateViews();

%-------------------------------------------------------------------------%
   function data = createData(seg)
      
      if isa(seg,'SampledProcess')
         for i = 1:numel(seg)
            segment(i) = Segment('process',...
               {seg(i) EventProcess()});
         end
      elseif isa(seg,'PointProcess')
         for i = 1:numel(seg)
            segment(i) = Segment('process',...
               {seg(i) EventProcess()});
         end
      elseif isa(seg,'Segment')
         segment = seg;
      else
         error('bad input');
      end
      
      data.segment = segment;
      [data.plotS,data.plotP,data.plotE] = countProcesses(seg(1));
   end % createData

   function [nS,nP,nE] = countProcesses(seg)
      nS = sum(strcmp(seg.type,'SampledProcess'));
      nP = sum(strcmp(seg.type,'PointProcess'));
      nE = sum(strcmp(seg.type,'EventProcess'));
   end

%-------------------------------------------------------------------------%
   function gui = createInterface()
      gui = struct();
      
      sz = hw.screensize;
      % Open a window and add some menus
      gui.Window = figure(...
         'Name','Process browser',...
         'NumberTitle','off',...
         'MenuBar','none',...
         'Toolbar','figure',...
         'Position',[200 200 1250 750],...
         'Visible','off',...
         'HandleVisibility','on');
      
      % + File menu
      gui.FileMenu = uimenu(gui.Window,'Label','File');
      uimenu(gui.FileMenu,'Label','Load','Callback',@onExit);
      uimenu(gui.FileMenu,'Label','Exit','Callback',@onExit);
     
      a = findall(gui.Window);
      rmTools = {'Save Figure' 'New Figure' 'Print Figure' 'Edit Plot' ...
         'Rotate 3D' 'Link Plot' 'Insert Colorbar' 'Hide Plot Tools' ...
         'Show Plot Tools and Dock Figure'};
      for i = 1:numel(rmTools)
         b = findall(a,'ToolTipString',rmTools{i});
         set(b,'Visible','Off');
         delete(b);
      end
      
      % + Create the panels
      gui.HBox = uix.HBox('Parent',gui.Window,'Spacing',5,'Padding',5);
      controlPanel = uix.BoxPanel('Parent',gui.HBox);
      
      % Panels and axes for data
      [gui.ViewGrid,gui.ViewPanelS,gui.ViewPanelP] = createViewPanels(gui.HBox,data);
      
      % set HBox elements sizes, fix control panel
      set(gui.HBox,'Widths',[175 -1]);
            
      figHeight = get(gui.Window,'Position');
      figHeight = figHeight(end);
      
      gui.RedrawButton = uicontrol('parent',gui.Window,'Style','pushbutton',...
         'String','Redraw','Fontsize',14,...
         'Position',[35,figHeight-500,110,35],'Callback',@onRedrawButton);

      gui.EventsButton = uicontrol('parent',gui.Window,'Style','radio',...
         'String','Plot Events','Fontsize',14,...
         'Position',[20,figHeight-150,110,35],'Callback',@onEventsButton);

      gui.StackButton = uicontrol('parent',gui.Window,'style','radio',...
         'position',[20,figHeight-50,80,25],'Fontsize',14,...
         'String','Stack','Callback',@onStackButton);
      
      gui.ScaleSlider = uicontrol('parent',gui.Window,'style','slider',...
         'position',[43,figHeight-100,125-23,25],'Callback', @onScaleSlider);
      set(gui.ScaleSlider,'Min',0,'Max',6,'Value',0);

      gui.ScaleSliderTxt = uicontrol('parent',gui.Window,'Style','text',...
         'String','Stack separation 0 SD','HorizontalAlignment','Left',...
         'Position',[43,figHeight-75,125,25],'Fontsize',10);
      
      gui.MousePanButton = uicontrol('parent',gui.Window,'style','radio',...
         'position',[20,figHeight-125,150,25],'Fontsize',14,...
         'String','Interactive zoom','Callback',@onMousePanButton);

      n = numel(data.segment);
      gui.ArraySlider = uicontrol('parent',gui.Window,'style','slider',...
         'position',[25,figHeight-400,125,25]);
      set(gui.ArraySlider,'Min',1,'Max',n);
      set(gui.ArraySlider,'SliderStep', [1 5] / max(1,n - 1),'Value',1);
      set(gui.ArraySlider,'Callback', @onArraySlider);

      gui.ArraySliderTxt = uicontrol('parent',gui.Window,'Style','text',...
         'String',['Array 1/' num2str(n)],...
         'Position',[25,figHeight-375,125,25],'Fontsize',14);
      
      n = size(data.segment(1).window,1);
      gui.WindowSlider = uicontrol('parent',gui.Window,'style','slider',...
         'position',[25,figHeight-350,125,25],'Callback',@(h,e)disp('slide me'));
      set(gui.WindowSlider,'Min',1,'Max',n);
      set(gui.WindowSlider,'SliderStep', [1 5] / max(1,n - 1),'Value', 1);
      
      gui.WindowSliderTxt = uicontrol('parent',gui.Window,'Style','text',...
         'String',['Window 1/' num2str(n)],...
         'Position',[25,figHeight-325,125,25],'Fontsize',14);
             
      set(gui.Window,'Visible','on');
      set(gui.Window,'SizeChangedFcn',@onResize)
   end % createInterface
%-------------------------------------------------------------------------%
   function [ViewGrid,ViewPanelS,ViewPanelP] = createViewPanels(hbox,data)
      ViewGrid = uix.GridFlex('Parent',hbox,'Spacing',5);
      heights = [];
      if data.plotS
         for i = 1:data.plotS
            ViewPanelS(i) = uix.BoxPanel('Parent',ViewGrid,...
               'Title','Sampled Process','TitleColor',[.5 .5 .5],...
               'BorderType','beveledout','FontSize',16,'FontAngle','italic');
            axS(i) = axes( 'Parent', uicontainer('Parent',ViewPanelS(i)),...
               'Position',[.075 .1 .9 .8],...
               'tickdir','out','Tag',['Sampled Process Axis ' num2str(i)],...
               'ActivePositionProperty','outerposition');
            heights = [heights -1.75];
         end
      else
         ViewPanelS = uix.BoxPanel('Parent',ViewGrid,...
            'Title','Sampled Process','TitleColor',[.5 .5 .5],...
            'BorderType','beveledout','FontSize',16,'FontAngle','italic');
         heights = [heights 0];
      end
      if data.plotP
         for i = 1:data.plotP
            ViewPanelP(i) = uix.BoxPanel('Parent',ViewGrid,...
               'Title','Point Process','TitleColor',[.5 .5 .5],...
               'BorderType','beveledout','FontSize',16,'FontAngle','italic');
            axP(i) = axes( 'Parent', uicontainer('Parent',ViewPanelP(i)),...
               'Position', [.075 .2 .9 .6],...
               'tickdir','out','Tag',['Point Process Axis ' num2str(i)],...
               'ActivePositionProperty','outerposition');
            heights = [heights -1];
         end
      else
         ViewPanelP = uix.BoxPanel('Parent',ViewGrid,...
            'Title','Point Process','TitleColor',[.5 .5 .5],...
            'BorderType','beveledout','FontSize',16,'FontAngle','italic');
         heights = [heights 0];
      end
      
      set(ViewGrid,'Heights',heights);
      
      if exist('axS','var') && exist('axP','var')
         linkaxes([axS,axP],'x');
      end
   end
%-------------------------------------------------------------------------%
   function onResize( ~, ~ )
      figHeight = get(gui.Window,'Position');
      figHeight = figHeight(end);
      
      temp = get(gui.RedrawButton,'Position');
      set(gui.RedrawButton,'Position',[temp(1) figHeight-500 temp(3) temp(4)]);
      temp = get(gui.StackButton,'Position');
      set(gui.StackButton,'Position',[temp(1) figHeight-50 temp(3) temp(4)]);
      temp = get(gui.EventsButton,'Position');
      set(gui.EventsButton,'Position',[temp(1) figHeight-150 temp(3) temp(4)]);
      temp = get(gui.ScaleSlider,'Position');
      set(gui.ScaleSlider,'Position',[temp(1) figHeight-100 temp(3) temp(4)]);
      temp = get(gui.ScaleSliderTxt,'Position');
      set(gui.ScaleSliderTxt,'Position',[temp(1) figHeight-75 temp(3) temp(4)]);
      temp = get(gui.MousePanButton,'Position');
      set(gui.MousePanButton,'Position',[temp(1) figHeight-125 temp(3) temp(4)]);
      temp = get(gui.ArraySlider,'Position');
      set(gui.ArraySlider,'Position',[temp(1) figHeight-400 temp(3) temp(4)]);
      temp = get(gui.ArraySliderTxt,'Position');
      set(gui.ArraySliderTxt,'Position',[temp(1) figHeight-375 temp(3) temp(4)]);
      temp = get(gui.WindowSlider,'Position');
      set(gui.WindowSlider,'Position',[temp(1) figHeight-350 temp(3) temp(4)]);
      temp = get(gui.WindowSliderTxt,'Position');
      set(gui.WindowSliderTxt,'Position',[temp(1) figHeight-325 temp(3) temp(4)]);

   end % onResize

%-------------------------------------------------------------------------%
   function updateViews()
      updateViewPanelP();
      updateViewPanelS();
      updateEvents();
   end % updateViews
%-------------------------------------------------------------------------%
   function updateViewPanelS()
      if data.plotS
         plotS();
      end
   end
%-------------------------------------------------------------------------%
   function updateViewPanelP()
      if data.plotP
         plotP();
      end
   end
%-------------------------------------------------------------------------%
   function updateEvents()
      if get(gui.EventsButton,'Value')
         plotE();
      end
   end
%-------------------------------------------------------------------------%
   function plotS()
      ind = get(gui.ArraySlider,'Value');
      ax = findobj(gui.ViewPanelS,'Tag','Sampled Process Axis 1');
      axes(ax);
            
      cla(ax); hold on;
      plot(data.segment(ind).sampledProcess,'handle',ax,...
         'stack',get(gui.StackButton,'Value'),...
         'sep',get(gui.ScaleSlider,'Value')*data.sd);
      axis tight;
   end
%-------------------------------------------------------------------------%
   function plotP()
      ind = get(gui.ArraySlider,'Value');
      ax = findobj(gui.ViewPanelP,'Tag','Point Process Axis 1');
      axes(ax);
      
      cla(ax);
      raster(data.segment(ind).pointProcess,'handle',ax,'style','tick');
      axis([get(ax,'xlim') 0.5 max(get(ax,'ylim'))]);
   end
%-------------------------------------------------------------------------%
   function plotE()
      ind = get(gui.ArraySlider,'Value');
      
      ax = findobj(gui.ViewPanelS,'Tag','Sampled Process Axis 1');
      plot(data.segment(ind).eventProcess,'handle',ax);
   end
%-------------------------------------------------------------------------%
   function onRedrawButton(~,~)
      fig.interactivemouse('OFF');
      set(gui.MousePanButton,'Value',0);
      updateViews();
   end % redrawDemo
%-------------------------------------------------------------------------%
   function onEventsButton(~,~)
      if get(gui.EventsButton,'Value')
         plotE();
      else
         delete(findobj(gui.ViewPanelS,'Tag','Event'));
      end
   end % redrawDemo

%-------------------------------------------------------------------------%
   function onMousePanButton( ~, ~ )
      zoom off;
      fig.interactivemouse;
   end % onMenuSelection

%-------------------------------------------------------------------------%
   function onArraySlider( ~, ~ )
      set(gui.ArraySlider,'Value',ceil(get(gui.ArraySlider,'Value')));
      set(gui.ArraySliderTxt,'String',...
         ['Array ' num2str(get(gui.ArraySlider,'Value')) '/'...
         num2str(numel(data.segment))])
      updateViews();
   end % onHelp
%-------------------------------------------------------------------------%
   function onStackButton( ~, ~ )
      if data.plotS
         set(gui.MousePanButton,'Value',0);
         fig.interactivemouse('OFF');
         
         ind = get(gui.ArraySlider,'Value');
         data.sd = getCurrentSD(ind);
         
         if get(gui.StackButton,'Value')
            set(gui.ScaleSlider,'Value',3);
            set(gui.ScaleSliderTxt,'String','Stack separation 3 SD');
         else
            set(gui.ScaleSlider,'Value',0);
            set(gui.ScaleSliderTxt,'String','Stack separation 0 SD');
         end
         
         updateViewPanelS();
         updateEvents();
      end
   end % onHelp
%-------------------------------------------------------------------------%
   function sd = getCurrentSD(ind)
      values = data.segment(ind).sampledProcess.values{1};
      sd = max(nanstd(values));
   end
%-------------------------------------------------------------------------%
   function onScaleSlider( ~, ~ )
      if get(gui.StackButton,'Value')
         set(gui.ScaleSliderTxt,'String',...
            ['Stack separation ' sprintf('%1.1f',(get(gui.ScaleSlider,'Value'))) ' SD']);
         updateViewPanelS();
         updateEvents();
      else
         set(gui.ScaleSlider,'Value',0);
         set(gui.ScaleSliderTxt,'String','Stack separation 0 SD');
      end
   end % onExit

%-------------------------------------------------------------------------%
   function onExit( ~, ~ )
      % User wants to quit out of the application
      delete( gui.Window );
   end % onExit

end % EOF