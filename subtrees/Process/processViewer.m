function processViewer(seg)
% Data is shared between all child functions by declaring the variables
% here (all functions are nested). We keep things tidy by putting
% all GUI stuff in one structure and all data stuff in another.
data = createData(seg);
% if data.plotS
%    data.sd = getCurrentSD(1);
% end
data.sd = 1;
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
   end % createData
   
   function [processTypes,processLabels,processEnables] = countProcesses(seg,validProcesses)
      processTypes = intersect(seg.type,validProcesses,'stable');
      processLabels = cell(1,numel(processTypes));
      processEnables = cell(1,numel(processTypes));
      for i = 1:numel(processTypes)
         ind = strcmp(seg.type,processTypes{i});
         if any(ind)
            processLabels{i} = seg.labels(ind);
            processEnables{i} = true(sum(ind));
         end
      end
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
         delete(b);
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
      [gui.ViewTab,gui.ViewPanel] = ...
         createViewPanels(gui.HBox,data);
      
      % Fix control panel width
      set(gui.HBox,'Widths',[225 -1]);
      
      top = 220;      
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
      controlBoxUpper = uix.BoxPanel('Parent',controlBox,'Units','pixels',...
               'Title','ControlBoxUpper','TitleColor',[.5 .5 .5],...
               'BorderType','beveledout');
      controlBoxLower = uix.BoxPanel('Parent',controlBox,'Units','pixels',...
               'Title','ControlBoxLower','TitleColor',[.5 .5 .5],...
               'BorderType','beveledout');
      set(controlBox,'Heights',[310 450]);
      
      h1 = uitabgroup('Parent',controlBoxUpper,'Units','pixels');
      upperTab1 = uitab(h1,'title','View','Units','pixels');
      upperTab2 = uitab(h1,'title','Test');
      
      h2 = uitabgroup('Parent',controlBoxLower);
      lowerTab1 = uitab(h2,'title','Sync');
      lowerTab2 = uitab(h2,'title','Select');
   end % createControlPanels
%-------------------------------------------------------------------------%
   function [ViewTab,ViewPanel] = createViewPanels(hbox,data)
      ViewTab = uix.TabPanel('Parent',hbox,'Padding',5,'FontSize',18,...
         'SelectionChangedFcn',@shit);

      % Find all unique processes 
      labels = cat(2,data.segment.labels);
      type = cat(2,data.segment.type);
      labels = labels(~strcmp(type,'EventProcess'));
      type = type(~strcmp(type,'EventProcess'));
      [uLabels,I] = unique(labels,'stable');
      uType = type(I);
  
      % Setup a separate tab for all possible processes
      for i = 1:numel(uLabels)
         ViewPanel(i) = uix.VBox('Parent',ViewTab,'Tag',uLabels{i});
         createViewPanelControl(ViewPanel(i),uType{i},[uLabels{i} '_ViewPanelControl']);
         switch uType{i}
            case {'SampledProcess', 'PointProcess'}
               axes('Parent', uicontainer('Parent',ViewPanel(i)),...
                  'tickdir','out','Tag',uLabels{i},...
                  'ActivePositionProperty','outerposition');
            case 'SpectralProcess'
               uipanel('Parent',ViewPanel(i),'Tag',uLabels{i});
         end
         set(ViewPanel(i), 'Heights', [100 -2],'Spacing',5);
      end
      
      % TODO handle empty case?

      ViewTab.TabTitles = uLabels;
      ViewTab.TabWidth = 200;
      
%       if exist('ax','var')
%          linkaxes(ax,'x');
%       end
   end
%-------------------------------------------------------------------------%
   function ViewPanelControl = createViewPanelControl(ViewPanel,type,tag)
      ViewPanelControl = uipanel('Parent',ViewPanel,'Units','pixels','Tag',tag);
      switch type
         case 'SampledProcess'
            uicontrol('parent',ViewPanelControl,'Style','text',...
               'String','Stack separation 0 SD','HorizontalAlignment','Left',...
               'Position',[15,35,125,25],'Fontsize',10,'Tag','StackSliderText');
            StackSlider = uicontrol('parent',ViewPanelControl,'style','slider',...
               'position',[15,15,125,25],'Callback', @onStackSlider,'Tag','StackSlider');
            set(StackSlider,'Min',0,'Max',6,'Value',0);
            uicontrol('parent',ViewPanelControl,'style','checkbox',...
               'position',[5,65,80,25],'Fontsize',14,'Tag','Stack',...
               'String','Stack','Callback',@onStackButton);
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
      gui.SelectInfoPopup.Value = 1;
      gui.SelectPropPopup.String = {'none'};
      gui.SelectPropPopup.Value = 1;
      gui.SelectValuePopup.String = {'none'};
      gui.SelectValuePopup.Value = 1;
   end
%-------------------------------------------------------------------------%
   function updateViews()
      ind = gui.ArraySlider.Value;
 
      % Determine number of active views
      validProcesses = {'SampledProcess' 'PointProcess' 'SpectralProcess'};
      [gui.processTypes,gui.processLabels,gui.processEnables] = ...
         countProcesses(data.segment(ind),validProcesses);
      
      % Toggle visibility of active tabs
      [~,I] = intersect(gui.ViewTab.TabTitles,cell.flatten(gui.processLabels));
      gui.ViewTab.TabEnables(I) = {'on'};
%      shit(gui.ViewTab)
%keyboard
%       % Update active views
%       for i = 1:numel(gui.processTypes)
%          for j = 1:numel(gui.processLabels{i})
%             ax = findobj(gui.ViewPanel,'Tag',gui.processLabels{i}{j});
%             set(ax,'Visible','on');
%             updatePlots(ind,gui.processTypes{i},gui.processLabels{i}{j});
%             updateEvents(ind,gui.processLabels{i}{j});
%          end
%       end

      % Toggle visibility off on inactive views
      I2 = true(size(gui.ViewTab.TabTitles));
      I2(I) = false;
      I2 = find(I2);
      gui.ViewTab.TabEnables(I2) = {'off'};
      for i = 1:numel(I2)
         ax = findobj(gui.ViewPanel,'Tag',gui.ViewTab.TabTitles{I2(i)});
         set(ax,'Visible','off');
      end
   end % updateViews
   function shit(source,~)
      if exist('gui','var')
         ind = gui.ArraySlider.Value;
         label = get(source.Children(source.Selection),'Tag');

         labels = cell.flatten(gui.processLabels);
         type = gui.processTypes{strcmp(labels,label)};
         panel = findobj(gui.ViewPanel,'Tag',label);
         set(panel,'Visible','on');
         updatePlots(ind,type,label);
         updateEvents(ind,label);
      end
   end
%-------------------------------------------------------------------------%
   function updatePlots(ind,type,labels)
      if ischar(labels)
         labels = {labels};
      end
      for i = 1:numel(labels)
         
         switch type
            case 'SampledProcess'
               ax = findobj(gui.ViewPanel,'Tag',labels{i},'-and','Type','Axes');
               axes(ax); cla(ax); set(ax,'Visible','on');
               viewPanelControl = findobj(gui.ViewPanel,'Tag',[labels{i} '_ViewPanelControl']);
               stack = findobj(viewPanelControl,'Tag','Stack','-depth',1);
               stackSlider = findobj(viewPanelControl,'Tag','StackSlider','-depth',1);
               plot(extract(data.segment(ind),labels{i},'labels'),'handle',ax,...
                  'stack',stack.Value,...
                  'sep',stackSlider.Value*data.sd);
               axis tight;
            case 'PointProcess'
               ax = findobj(gui.ViewPanel,'Tag',labels{i},'-and','Type','Axes');
               axes(ax); cla(ax); set(ax,'Visible','on');
               raster(extract(data.segment(ind),labels{i},'labels'),'handle',ax,'style','tick');
               axis([get(ax,'xlim') 0.5 max(get(ax,'ylim'))]);
            case 'SpectralProcess'
               ax = findobj(gui.ViewPanel,'Tag',labels{i},'-and','Type','UIPanel');
               set(ax(1),'Visible','on');
               plot(extract(data.segment(ind),labels{i},'labels'),'handle',ax(1),'colorbar',false);
         end
      end
   end
%-------------------------------------------------------------------------%
   function updateEvents(ind,labels)
      if get(gui.EventsButton,'Value')
         plotE(ind,labels);
      end
   end
%-------------------------------------------------------------------------%
   function plotE(ind,labels)
      if nargin < 2
         labelsS = data.segment(ind).labels(strcmp(data.segment(ind).type,'SampledProcess'));
         labelsP = data.segment(ind).labels(strcmp(data.segment(ind).type,'PointProcess'));
         labels = cat(2,labelsS,labelsP);
      end
      if ischar(labels)
         labels = {labels};
      end
      for i = 1:numel(labels)
         ax = findobj(gui.ViewPanel,'Tag',labels{i},'-and','Type','Axes');
         plot(data.segment(ind).eventProcess,'handle',ax);
      end
   end
%-------------------------------------------------------------------------%
   function onEventsButton(~,~)
      if gui.EventsButton.Value
         plotE(gui.ArraySlider.Value);
      else
         delete(findobj(gui.ViewPanel,'Tag','Event'));
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
      else
         gui.ArraySlider.Value = ceil(gui.ArraySlider.Value');
      end
      gui.ArraySliderTxt.String = ...
         ['Array ' num2str(get(gui.ArraySlider,'Value')) '/'...
         num2str(numel(data.segment))];
      updateViews();
      updateSyncTab();
   end % onArraySlider
%-------------------------------------------------------------------------%
   function onStackButton(source,~)
      ind = gui.ArraySlider.Value;
      
      viewPanelControl = get(source,'Parent');      
      stack = findobj(viewPanelControl,'Tag','Stack');
      stackSliderText = findobj(viewPanelControl,'Tag','StackSliderText');
      stackSlider = findobj(viewPanelControl,'Tag','StackSlider');

      if stack.Value
         stackSlider.Value = 3;
         stackSliderText.String = 'Stack separation 3 SD';
      else
         stackSlider.Value = 0;
         stackSliderText.String = 'Stack separation 0 SD';
      end
      updatePlots(ind,'SampledProcess',get(get(viewPanelControl,'Parent'),'Tag'));
      updateEvents(ind,viewPanelControl.Tag);
      
%       if data.plotS
%          gui.MousePanButton.Value = 0;
%          fig.interactivemouse('OFF');
%          
%          ind = gui.ArraySlider.Value;
%          data.sd = getCurrentSD(ind);
%       end
   end % onStackButton
%-------------------------------------------------------------------------%
   function sd = getCurrentSD(ind)
      try
         % FIXME for multiple sampledProcesses
         extract(data.segment(ind),labels{i},'labels')
         
         values = data.segment(ind).sampledProcess.values{1};
         sd = max(nanstd(values));
      catch
         sd = 1;
      end
   end
%-------------------------------------------------------------------------%
   function onStackSlider(source,~)
      ind = gui.ArraySlider.Value;
      
      viewPanelControl = get(source,'Parent');      
      stack = findobj(viewPanelControl,'Tag','Stack');
      stackSliderText = findobj(viewPanelControl,'Tag','StackSliderText');
      stackSlider = findobj(viewPanelControl,'Tag','StackSlider');
      
      if stack.Value
         stackSliderText.String = ...
            ['Stack separation ' sprintf('%1.1f',(get(stackSlider,'Value'))) ' SD'];
         updatePlots(ind,'SampledProcess',get(get(viewPanelControl,'Parent'),'Tag'));
         updateEvents(ind,get(get(viewPanelControl,'Parent'),'Tag'));
      else
         stackSlider.Value = 0;
         stackSliderText.String = 'Stack separation 0 SD';
      end
   end % onStackSlider
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
         if iscell(str.array)
            str = str.distinct().toList();
         else
            str = str.distinct().toArray();
            if islogical(str)
               str = double(str);
            end
         end
         gui.SelectValuePopup.String = str;
      else
         gui.SelectValuePopup.String = 'none';
      end
   end
%-------------------------------------------------------------------------%
   function onSelectValuePopup(~,~)
   end
%-------------------------------------------------------------------------%
   function onSelectButton(~,~)
      key = gui.SelectInfoPopup.String{gui.SelectInfoPopup.Value};
      prop = gui.SelectPropPopup.String{gui.SelectPropPopup.Value};
      try
         value = gui.SelectValuePopup.String{gui.SelectValuePopup.Value};
         isNumeric = false;
      catch
         value = str2num(gui.SelectValuePopup.String(gui.SelectValuePopup.Value));
         isNumeric = true;
      end
      
      q = linq(data.segment);
      if isNumeric
         temp = q.where(@(x) isKey(x.info,key))...
            .where(@(x) isprop(x.info(key),prop) || isfield(x.info(key),prop))...
            .where(@(x) x.info(key).(prop) == value).toArray();
      else
         temp = q.where(@(x) isKey(x.info,key))...
            .where(@(x) isprop(x.info(key),prop) || isfield(x.info(key),prop))...
            .where(@(x) strcmp(x.info(key).(prop),value)).toArray();
      end

      data = createData(temp);
      if data.plotS
         data.sd = getCurrentSD(1);
      end
      updateViews();
      updateSyncTab();
      updateSelectTab();
   end
%-------------------------------------------------------------------------%
   function onSelectResetButton(~,~)
      data = createData(seg);
      if data.plotS
         data.sd = getCurrentSD(1);
      end
      updateViews();
      updateSyncTab();
      updateSelectTab();
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
      delete(gui.Window);
   end % onExit

end % EOF