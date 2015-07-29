function gui = processViewer(seg)
% Data is shared between all child functions by declaring the variables
% here (all functions are nested). We keep things tidy by putting
% all GUI stuff in one structure and all data stuff in another.
data = createData(seg);
if data.plotS
   data.sd = getCurrentSD(1);
end
gui = createInterface();
updateViews();
updateSyncTab();
updateSelectTab();

%-------------------------------------------------------------------------%
   function data = createData(seg)
      if isa(seg,'SampledProcess') || isa(seg,'PointProcess')
         for i = 1:numel(seg)
            segment(i) = Segment('process',{seg(i) EventProcess()});
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
      
      sz = get(0,'ScreenSize');
      % Open a window and add some menus
      gui.Window = figure(...
         'Name','Process browser',...
         'NumberTitle','off',...
         'MenuBar','none',...
         'Toolbar','figure',...
         'OuterPosition',[sz(1:2)+50 sz(3:4)-100],...
         'Visible','off',...
         'HandleVisibility','on');
            
      % + File menu
      gui.FileMenu = uimenu(gui.Window,'Label','File');
      uimenu(gui.FileMenu,'Label','Load','Callback',@onExit);
      uimenu(gui.FileMenu,'Label','Exit','Callback',@onExit);
      
      % Remove some toolbar elements
      a = findall(gui.Window);
      rmTools = {'Save Figure' 'New Figure' 'Print Figure' 'Edit Plot' ...
         'Rotate 3D' 'Link Plot' 'Insert Colorbar' 'Hide Plot Tools' ...
         'Show Plot Tools and Dock Figure'};
      for i = 1:numel(rmTools)
         b = findall(a,'ToolTipString',rmTools{i});
         delete(b);%set(b,'Visible','Off');
      end
      %       hToolLegend = findall(gcf,'tag','Annotation.InsertLegend');
      %       set(hToolLegend, 'ClickedCallback',@cbLegend);
      
      % + Create the panels
      gui.HBox = uix.HBox('Parent',gui.Window,'Spacing',5,'Padding',5);
      
      % Control panels and tabs
      [gui.controlBox,gui.controlBoxUpper,gui.controlBoxLower,...
         gui.upperTab1,gui.upperTab2,gui.lowerTab1,gui.lowerTab2] = ...
         createControlPanels(gui.HBox);
      
      % Panels and axes for data
      [gui.ViewGrid,gui.ViewPanelS,gui.ViewPanelP] = ...
         createViewPanels(gui.HBox,data);
      
      % Fix control panel width
      set(gui.HBox,'Widths',[225 -1]);
      
      top = 220;
      gui.ScaleSliderTxt = uicontrol('parent',gui.upperTab1,'Style','text',...
         'String','Stack separation 0 SD','HorizontalAlignment','Left',...
         'Position',[43,top-25,125,20],'Fontsize',10);
      gui.StackButton = uicontrol('parent',gui.upperTab1,'style','checkbox',...
         'position',[10,top,80,25],'Fontsize',14,...
         'String','Stack','Callback',@onStackButton);
      
      gui.ScaleSlider = uicontrol('parent',gui.upperTab1,'style','slider',...
         'position',[43,top-50,125-23,25],'Callback', @onScaleSlider);
      set(gui.ScaleSlider,'Min',0,'Max',6,'Value',0);
      
      gui.EventsButton = uicontrol('parent',gui.upperTab1,'Style','checkbox',...
         'String','Plot Events','Fontsize',14,...
         'Position',[10,top-75,110,25],'Callback',@onEventsButton);
      
      gui.MousePanButton = uicontrol('parent',gui.upperTab1,'style','checkbox',...
         'position',[10,top-100,150,25],'Fontsize',14,...
         'String','Interactive zoom','Callback',@onMousePanButton);
      
      n = numel(data.segment);
      gui.ArraySliderTxt = uicontrol('parent',gui.upperTab1,'Style','text',...
         'String',['Array 1/' num2str(n)],...
         'Position',[20,top-150,150,25],'Fontsize',14);
      gui.ArraySlider = uicontrol('parent',gui.upperTab1,'style','slider',...
         'position',[20,top-175,150,25]);
      set(gui.ArraySlider,'Min',1,'Max',n);
      set(gui.ArraySlider,'SliderStep', [1 5] / max(1,n - 1),'Value',1);
      set(gui.ArraySlider,'Callback', @onArraySlider);
      
      n = size(data.segment(1).window,1);
      gui.WindowSliderTxt = uicontrol('parent',gui.upperTab1,'Style','text',...
         'String',['Window 1/' num2str(n)],...
         'Position',[20,top-200,150,25],'Fontsize',14);
      gui.WindowSlider = uicontrol('parent',gui.upperTab1,'style','slider',...
         'position',[20,top-225,150,25],'Callback',@(h,e)disp('slide me'));
      set(gui.WindowSlider,'Min',1,'Max',n);
      set(gui.WindowSlider,'SliderStep', [1 5] / max(1,n - 1),'Value', 1);
      
      % + Sync tab
      top = 350;
      uicontrol('Parent',gui.lowerTab1,'Style','text',...
         'String','Use event prop','Fontsize',14,'HorizontalAlignment','left',...
         'Position', [10 top 150 25]);
      gui.SyncPropPopup = uicontrol('Parent',gui.lowerTab1,'Style','popup',...
         'String', {'name'},'Fontsize',14,...
         'Position', [110 top 90 25]);
      uicontrol('Parent',gui.lowerTab1,'Style','text',...
         'String','synchronize to','Fontsize',14,'HorizontalAlignment','left',...
         'Position', [10 top-25 150 25]);
      gui.SyncEventsPopup = uicontrol('Parent',gui.lowerTab1,'Style','popup',...
         'String', {'none'},'Fontsize',14,...
         'Position', [110 top-25 90 25]);
      uicontrol('Parent',gui.lowerTab1,'Style','text',...
         'String','using event','Fontsize',14,'HorizontalAlignment','left',...
         'Position', [10 top-50 150 25]);
      gui.SyncEdgePopup = uicontrol('Parent',gui.lowerTab1,'Style','popup',...
         'String', {'start' 'end'},'Fontsize',14,...
         'Position', [110 top-50 90 25]);
      uicontrol('Parent',gui.lowerTab1,'Style','text',...
         'String','w/ window','Fontsize',14,'HorizontalAlignment','left',...
         'Position', [10 top-75 150 25]);
      gui.SyncWindowStart = uicontrol('Parent',gui.lowerTab1,'Style','edit',...
         'String','-2.5','Value',-2.5,'Fontsize',12,...
         'Position', [80 top-70 45 20],'Callback',@onSyncWindowStart);
      uicontrol('Parent',gui.lowerTab1,'Style','text',...
         'String','to','Fontsize',14,'HorizontalAlignment','left',...
         'Position', [128 top-75 15 25]);
      gui.SyncWindowEnd = uicontrol('Parent',gui.lowerTab1,'Style','edit',...
         'String','2.5','Value',2.5,'Fontsize',12,...
         'Position', [148 top-70 45 20],'Callback',@onSyncWindowEnd);
      gui.SyncButton = uicontrol('parent',gui.lowerTab1,'style','pushbutton',...
         'position',[35,top-175,125,35],'Fontsize',14,...
         'String','Sync','Callback',@onSyncButton);
      gui.SyncAllButton = uicontrol('parent',gui.lowerTab1,'style','pushbutton',...
         'position',[35,top-225,125,35],'Fontsize',14,...
         'String','Sync all','Callback',@onSyncAllButton);
      gui.SyncResetButton = uicontrol('parent',gui.lowerTab1,'style','pushbutton',...
         'position',[35,top-275,125,35],'Fontsize',14,...
         'String','Reset','Callback',@onSyncResetButton);
      
      % + Select tab
      top = 350;
      uicontrol('Parent',gui.lowerTab2,'Style','text',...
         'String','Use info key','Fontsize',14,'HorizontalAlignment','left',...
         'Position', [10 top 150 25]);
      gui.SelectInfoPopup = uicontrol('Parent',gui.lowerTab2,'Style','popup',...
         'String', {'none'},'Fontsize',14,...
         'Position', [110 top 90 25], 'Callback', @onSelectInfoPopup);
      uicontrol('Parent',gui.lowerTab2,'Style','text',...
         'String','and property','Fontsize',14,'HorizontalAlignment','left',...
         'Position', [10 top-25 150 25]);
      gui.SelectPropPopup = uicontrol('Parent',gui.lowerTab2,'Style','popup',...
         'String', {'none'},'Fontsize',14,...
         'Position', [110 top-25 90 25],'Callback',@onSelectPropPopup);
      uicontrol('Parent',gui.lowerTab2,'Style','text',...
         'String','select value','Fontsize',14,'HorizontalAlignment','left',...
         'Position', [10 top-50 150 25]);
      gui.SelectValuePopup = uicontrol('Parent',gui.lowerTab2,'Style','popup',...
         'String', {'none'},'Fontsize',14,...
         'Position', [110 top-50 90 25],'Callback',@onSelectValuePopup);
      gui.SelectButton = uicontrol('parent',gui.lowerTab2,'style','pushbutton',...
         'position',[35,top-225,125,35],'Fontsize',14,...
         'String','Select','Callback',@onSelectButton);
      gui.SelectResetButton = uicontrol('parent',gui.lowerTab2,'style','pushbutton',...
         'position',[35,top-275,125,35],'Fontsize',14,...
         'String','Reset','Callback',@onSelectResetButton);
      
      gui.Window.Visible = 'on';
   end % createInterface
%-------------------------------------------------------------------------%
   function [controlBox,controlBoxUpper,controlBoxLower,upperTab1,upperTab2,...
         lowerTab1,lowerTab2] = createControlPanels(hbox)
      controlBox = uix.VBox('Parent',hbox,'Spacing',5,...
         'Units','pixels');
      controlBoxUpper = uix.BoxPanel('Parent',controlBox,'Units','pixels');
      controlBoxLower = uix.BoxPanel('Parent',controlBox,'Units','pixels');
      set(controlBox,'Heights',[300 450]);
      
      h1 = uitabgroup('Parent',controlBoxUpper,'Units','pixels');
      upperTab1 = uitab(h1,'title','View','Units','pixels');
      upperTab2 = uitab(h1,'title','Test');
      
      h2 = uitabgroup('Parent',controlBoxLower);
      lowerTab1 = uitab(h2,'title','Sync');
      lowerTab2 = uitab(h2,'title','Select');
   end
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
      
      ViewGrid.Heights = heights;
      
      if exist('axS','var') && exist('axP','var')
         linkaxes([axS,axP],'x');
      end
   end
%-------------------------------------------------------------------------%
   function updateSyncTab()
      ind = gui.ArraySlider.Value;
      
      str = {'none' data.segment(ind).eventProcess.values{1}.name};
      gui.SyncEventsPopup.String = str;
      if isempty(data.segment(ind).validSync)
         gui.SyncEventsPopup.Value = 1;
      elseif isa(data.segment(ind).validSync,'metadata.Event')
         if strcmp(data.segment(ind).validSync.name,'NULL')
            gui.SyncEventsPopup.Value = 1;
         else
            ind = strcmp(data.segment(ind).validSync.name,str);
            gui.SyncEventsPopup.Value = find(ind);
         end
      end
   end
%-------------------------------------------------------------------------%
   function updateSelectTab()
      ind = gui.ArraySlider.Value;
      
      str = cat(2,'none',data.segment(ind).info.keys);
      gui.SelectInfoPopup.String = str;
   end
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
      ind = gui.ArraySlider.Value;
      ax = findobj(gui.ViewPanelS,'Tag','Sampled Process Axis 1');
      axes(ax);
      
      cla(ax); hold on;
      plot(data.segment(ind).sampledProcess,'handle',ax,...
         'stack',gui.StackButton.Value,...
         'sep',gui.ScaleSlider.Value*data.sd);
      axis tight;
   end
%-------------------------------------------------------------------------%
   function plotP()
      ind = gui.ArraySlider.Value;
      ax = findobj(gui.ViewPanelP,'Tag','Point Process Axis 1');
      axes(ax);
      
      cla(ax);
      raster(data.segment(ind).pointProcess,'handle',ax,'style','tick');
      axis([get(ax,'xlim') 0.5 max(get(ax,'ylim'))]);
   end
%-------------------------------------------------------------------------%
   function plotE()
      ind = gui.ArraySlider.Value;

      ax = findobj(gui.ViewPanelS,'Tag','Sampled Process Axis 1');
      if isempty(ax)
         ax = findobj(gui.ViewPanelP,'Tag','Point Process Axis 1');
      end
      plot(data.segment(ind).eventProcess,'handle',ax);
   end
%-------------------------------------------------------------------------%
   function onRedrawButton(~,~)
      fig.interactivemouse('OFF');
      gui.MousePanButton.Value = 0;
      updateViews();
   end % redrawDemo
%-------------------------------------------------------------------------%
   function onEventsButton(~,~)
      if gui.EventsButton.Value
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
      if gui.ArraySlider.Value >= gui.ArraySlider.Max
         gui.ArraySlider.Value = 1;
         %       elseif get(gui.ArraySlider,'Value') == get(gui.ArraySlider,'Min')
         %          set(gui.ArraySlider,'Value',get(gui.ArraySlider,'Max'));
      else
         gui.ArraySlider.Value = ceil(gui.ArraySlider.Value');
      end
      gui.ArraySliderTxt.String = ...
         ['Array ' num2str(get(gui.ArraySlider,'Value')) '/'...
         num2str(numel(data.segment))];
      updateViews();
      updateSyncTab();
   end % onHelp
%-------------------------------------------------------------------------%
   function onStackButton( ~, ~ )
      if data.plotS
         gui.MousePanButton.Value = 0;
         fig.interactivemouse('OFF');
         
         ind = gui.ArraySlider.Value;
         data.sd = getCurrentSD(ind);
         
         if gui.StackButton.Value
            gui.ScaleSlider.Value = 3;
            gui.ScaleSliderTxt.String = 'Stack separation 3 SD';
         else
            gui.ScaleSlider.Value = 0;
            gui.ScaleSliderTxt.String = 'Stack separation 0 SD';
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
      if gui.StackButton.Value
         gui.ScaleSliderTxt.String = ...
            ['Stack separation ' sprintf('%1.1f',(get(gui.ScaleSlider,'Value'))) ' SD'];
         updateViewPanelS();
         updateEvents();
      else
         gui.ScaleSlider.Value = 0;
         gui.ScaleSliderTxt.String = 'Stack separation 0 SD';
      end
   end % onExit
%-------------------------------------------------------------------------%
   function onSyncWindowStart(~,~)
      val = str2num(gui.SyncWindowStart.String);
      if isnumeric(val) && isscalar(val)
         gui.SyncWindowStart.Value = val;
      else
         error('bad value');
      end
   end
%-------------------------------------------------------------------------%
   function onSyncWindowEnd(~,~)
      val = str2num(gui.SyncWindowEnd.String);
      if isnumeric(val) && isscalar(val)
         gui.SyncWindowEnd.Value = val;
      else
         error('bad value');
      end
   end
%-------------------------------------------------------------------------%
   function onSyncButton(~,~)
      toggleBusy(gui.Window);
      ind = gui.ArraySlider.Value;
      eventName = gui.SyncEventsPopup.String{gui.SyncEventsPopup.Value};
      win = [gui.SyncWindowStart.Value gui.SyncWindowEnd.Value];
      
      eventStart = true;
      if strcmp(gui.SyncEdgePopup.String{gui.SyncEdgePopup.Value},'end')
         eventStart = false;
      end
      data.segment(ind).sync('name',eventName,'window',win,'eventStart',eventStart);
      updateViews();
      toggleBusy(gui.Window);
   end
%-------------------------------------------------------------------------%
   function onSyncAllButton(~,~)
      toggleBusy(gui.Window);
      eventName = gui.SyncEventsPopup.String{gui.SyncEventsPopup.Value};
      win = [gui.SyncWindowStart.Value gui.SyncWindowEnd.Value];
      
      tic;
      eventStart = true;
      if strcmp(gui.SyncEdgePopup.String{gui.SyncEdgePopup.Value},'end')
         eventStart = false;
      end
      data.segment.sync('name',eventName,'window',win,'eventStart',eventStart);
      toc
      updateViews();
      toggleBusy(gui.Window);
      
   end
%-------------------------------------------------------------------------%
   function onSyncResetButton(~,~)
      toggleBusy(gui.Window);
      data.segment.reset();
      updateSyncTab();
      updateViews();
      toggleBusy(gui.Window);
   end
%-------------------------------------------------------------------------%
   function onSelectInfoPopup(~,~)
      ind = gui.ArraySlider.Value;
      str = gui.SelectInfoPopup.String;
      indStr = gui.SelectInfoPopup.Value;
      if indStr > 1
         prop = data.segment(ind).info(str{indStr});
         if isa(prop,'metadata.Section')
            % TODO Filter out some invalid properties
            str = properties(prop);
         elseif isstruct(prop)
            str = fieldnames(prop);
         else
            str = 'none';
         end
      else
         str = 'none';
      end
      gui.SelectPropPopup.String = str;
   end
%-------------------------------------------------------------------------%
   function onSelectPropPopup(~,~)
      
      key = gui.SelectInfoPopup.String{gui.SelectInfoPopup.Value};
      prop = gui.SelectPropPopup.String{gui.SelectPropPopup.Value};
      
      q = linq(data.segment);
      str = q.where(@(x) isKey(x.info,key))...
         .where(@(x) isprop(x.info(key),prop) || isfield(x.info(key),prop))...
         .where(@(x) ~isempty(x.info(key).(prop)))...
         .select(@(x) x.info(key).(prop));
      
      if str.count > 0
         str = str.distinct().toArray();
         if islogical(str)
            str = double(str);
         end
         gui.SelectValuePopup.String = str;
      else
      end
   end
%-------------------------------------------------------------------------%
   function toggleBusy(h)
      persistent oldpointer;
      
      if isempty(oldpointer)
         oldpointer = h.Pointer;
         gui.Window.Pointer = 'watch';
         drawnow;
      else
         gui.Window.Pointer = oldpointer;
         oldpointer = [];
      end
   end
%-------------------------------------------------------------------------%
   function onExit(~,~)
      % User wants to quit out of the application
      delete(gui.Window);
   end % onExit

end % EOF