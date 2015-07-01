function processViewer(p)

% Data is shared between all child functions by declaring the variables
% here (they become global to the function). We keep things tidy by putting
% all GUI stuff in one structure and all data stuff in another. As the app
% grows, we might consider making these objects rather than structures.
data = createData(p);
gui = createInterface();

% Now update the GUI with the current data
updateInterface();
%redrawDemo();

% Explicitly call the demo display so that it gets included if we deploy
%displayEndOfDemoMessage('')

%-------------------------------------------------------------------------%
   function data = createData(p)
      data.p = p;
      data.plotS = 0;
      data.plotP = 0;
      data.plotE = 0;
      if isa(p,'SampledProcess')
         data.plotS = 1;
      elseif isa(p,'PointProcess')
         data.plotP = 1;
      elseif isa(p,'Segment')
         % HACK, take the first, assume the rest are the same for now
         proc = cell.uniqueRows(cat(1,p.type));
         procLabels = cell.uniqueRows(cat(1,p.labels));
         if (size(proc,1) == 1) && (size(procLabels,1) == 1)
            data.plotS = sum(strcmp(p(1).type,'SampledProcess'));
            data.plotP = sum(strcmp(p(1).type,'PointProcess'));
         else
            error('Different processes in each Segment element not supported');
         end
      end
   end % createData

%-------------------------------------------------------------------------%
   function gui = createInterface()
      gui = struct();
      
      sz = hw.screensize;
      % Open a window and add some menus
      gui.Window = figure( ...
         'Name', 'Process browser', ...
         'NumberTitle', 'off', ...
         'MenuBar', 'none', ...
         'Toolbar', 'none', ...
         'Position', [200 200 1250 750],...
         'Visible', 'off',...
         'HandleVisibility', 'on' );
      
      % + File menu
      gui.FileMenu = uimenu( gui.Window, 'Label', 'File' );
      uimenu( gui.FileMenu, 'Label', 'Load', 'Callback', @onExit );
      uimenu( gui.FileMenu, 'Label', 'Exit', 'Callback', @onExit );
      
      % + Create the panels
      b = uix.HBox( 'Parent', gui.Window, 'Spacing', 5, 'Padding', 5 );
      controlPanel = uix.BoxPanel( 'Parent', b );
      
      gui.ViewGrid = uix.GridFlex( 'Parent', b, 'Spacing', 5 );
      heights = [];
      if data.plotS
         for i = 1:data.plotS
            gui.ViewPanelS(i) = uix.BoxPanel( 'Parent', gui.ViewGrid,...
               'Title','Sampled Process','TitleColor',[.5 .5 .5],...
               'BorderType', 'beveledout', 'FontSize', 16, 'FontAngle', 'italic');
            axS(i) = axes( 'Parent', uicontainer('Parent',gui.ViewPanelS(i)), 'Position', [.075 .1 .9 .8],...
               'tickdir', 'out', 'Tag', ['Sampled Process Axis ' num2str(i)],...
               'ActivePositionProperty', 'outerposition');
            heights = [heights -1.75];
         end
      else
         gui.ViewPanelS = uix.BoxPanel( 'Parent', gui.ViewGrid,...
            'Title','Sampled Process','TitleColor',[.5 .5 .5],...
            'BorderType', 'beveledout', 'FontSize', 16, 'FontAngle', 'italic');
         heights = [heights 0];
      end
      if data.plotP
         for i = 1:data.plotP
            gui.ViewPanelP(i) = uix.BoxPanel( 'Parent', gui.ViewGrid,...
               'Title','Point Process','TitleColor',[.5 .5 .5],...
               'BorderType', 'beveledout', 'FontSize', 16, 'FontAngle', 'italic');
            axP(i) = axes( 'Parent', uicontainer('Parent',gui.ViewPanelP(i)), 'Position', [.075 .2 .9 .6],...
               'tickdir', 'out', 'Tag', ['Point Process Axis ' num2str(i)],...
               'ActivePositionProperty', 'outerposition');
            heights = [heights -1];
         end
      else
         gui.ViewPanelP = uix.BoxPanel( 'Parent', gui.ViewGrid,...
            'Title','Point Process','TitleColor',[.5 .5 .5],...
            'BorderType', 'beveledout', 'FontSize', 16, 'FontAngle', 'italic');
         heights = [heights 0];
      end
      
      set(gui.ViewGrid, 'Heights', heights );
      % set HBox elements sizes, fix control panel
      set( b, 'Widths', [175 -1] );
      
      if exist('axS','var') && exist('axP','var')
         linkaxes([axS,axP],'x');
      end
      
      figHeight = get(gui.Window,'Position');
      figHeight = figHeight(end);
      
      gui.RedrawButton = uicontrol('parent',gui.Window,'Style','pushbutton',...
         'String','Redraw','Fontsize', 14,...
         'Position',[35,figHeight-175,110,35],'Callback', @onRedrawButton);

      gui.EventsButton = uicontrol('parent',gui.Window,'Style','radio',...
         'String','Plot Events','Fontsize', 14,...
         'Position',[35,figHeight-210,110,35],'Callback', @onEventsButton);

      gui.StripsButton = uicontrol('parent',gui.Window,'style','radio',...
         'position',[20,figHeight-50,80,25], 'Fontsize', 14,...
         'String','Strips','Callback', @onStripsButton);
      
      gui.ScaleSlider = uicontrol('parent',gui.Window,'style','slider',...
         'position',[43,figHeight-100,125-23,25]);
      set(gui.ScaleSlider,'Min',0,'Max',6,'Value',0);
      set(gui.ScaleSlider,'Callback', @onScaleSlider);

      gui.ScaleSliderTxt = uicontrol('parent',gui.Window,'Style','text',...
         'String','Strips separation 0 SD','HorizontalAlignment','Left',...
         'Position',[43,figHeight-75,125,25],'Fontsize',10);
      
      gui.MousePanButton = uicontrol('parent',gui.Window,'style','radio',...
         'position',[20,figHeight-125,150,25], 'Fontsize', 14,...
         'String','Interactive zoom','Callback', @onMousePanButton);

      n = numel(data.p);
      gui.ArraySlider = uicontrol('parent',gui.Window,'style','slider',...
         'position',[25,figHeight-400,125,25]);
      set(gui.ArraySlider,'Min',1,'Max',n);
      set(gui.ArraySlider,'SliderStep', [1 5] / max(1,n - 1),'Value',1);
      set(gui.ArraySlider,'Callback', @onArraySlider);

      gui.ArraySliderTxt = uicontrol('parent',gui.Window,'Style','text',...
         'String',['Array 1/' num2str(n)],...
         'Position',[25,figHeight-375,125,25],'Fontsize',14);
      
      n = size(data.p(1).window,1);
      gui.WinSlider = uicontrol('parent',gui.Window,'style','slider',...
         'position',[25,figHeight-350,125,25]);
      set(gui.WinSlider,'Min',1,'Max',n);
      set(gui.WinSlider,'SliderStep', [1 5] / max(1,n - 1),'Value', 1);
      set(gui.WinSlider, 'Callback', @(h,e)disp('slide me'));
      
      gui.WinSliderTxt = uicontrol('parent',gui.Window,'Style','text',...
         'String',['Win 1/' num2str(n)],...
         'Position',[25,figHeight-325,125,25],'Fontsize',14);
             
      set(gui.Window,'Visible', 'on');
      set(gui.Window,'SizeChangedFcn', @onResize)
   end % createInterface
%-------------------------------------------------------------------------%
   function onResize( ~, ~ )
      figHeight = get(gui.Window,'Position');
      figHeight = figHeight(end);
      
      temp = get(gui.StripsButton,'Position');
      set(gui.StripsButton,'Position',[temp(1) figHeight-50 temp(3) temp(4)]);
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
      temp = get(gui.WinSlider,'Position');
      set(gui.WinSlider,'Position',[temp(1) figHeight-350 temp(3) temp(4)]);
      temp = get(gui.WinSliderTxt,'Position');
      set(gui.WinSliderTxt,'Position',[temp(1) figHeight-325 temp(3) temp(4)]);

   end % onResize

%-------------------------------------------------------------------------%
   function updateInterface()
      if data.plotP
         plotP();
      end
      if data.plotS
         plotS();
      end
      if get(gui.EventsButton,'Value')
         plotE();
      end
   end % updateInterface
%-------------------------------------------------------------------------%
   function plotS()
      strips = get(gui.StripsButton,'Value');
      ax = findobj(gui.ViewPanelS,'Tag','Sampled Process Axis 1');
      axes(ax);
      ind = get(gui.ArraySlider,'Value');
      
      if isa(data.p,'Segment')
         s = cell.flatten(extract(data.p,'SampledProcess','type'));
         values = s{ind}.values{1};
         t = s{ind}.times{1};
      else
         values = data.p(ind).values{1};
         t = data.p(ind).times{1};
      end

      cla(ax); hold on;
      if strips
         n = size(values,2);
         sf = (0:n-1)*get(gui.ScaleSlider,'Value')*data.sd;
         plot(t,bsxfun(@plus,values,sf));
         plot(repmat([t(1) t(end)]',1,n),[sf' , sf']','color',[.7 .7 .7 .4]);
      else
         plot(t,values);
      end
      axis tight;
   end
%-------------------------------------------------------------------------%
   function plotP()
      ax = findobj(gui.ViewPanelP,'Tag','Point Process Axis 1');
      axes(ax);
      ind = get(gui.ArraySlider,'Value');
      
      cla(ax);
      if isa(data.p,'Segment')
         pp = extract(data.p(ind),'PointProcess','type');
         raster(pp{1},'handle',ax,'style','tick');
      else
         raster(data.p,'handle',ax,'style','tick');
      end
      axis([get(ax,'xlim') 0.5 max(get(ax,'ylim'))]);
   end
%-------------------------------------------------------------------------%
   function plotE()
      if isa(data.p,'Segment')
         ax = findobj(gui.ViewPanelS,'Tag','Sampled Process Axis 1');
         axes(ax);
         ind = get(gui.ArraySlider,'Value');
         ep = extract(data.p(ind),'EventProcess','type');
         ep = ep{1};
         
         values = ep.values{1};
         ylim = get(ax,'ylim');
         
         c = fig.distinguishable_colors(numel(values));
         for i = 1:numel(values)
            left = values(i).time(1);
            right = values(i).time(2);
            bottom = ylim(1);
            top = ylim(2);
            eFill(i) = fill([left left right right],[bottom top top bottom],...
               c(i,:),'FaceAlpha',0.15,'EdgeColor','none');
            set(eFill(i),'Tag','Event');
            eText(i) = text(left,top,values(i).name,'VerticalAlignment','bottom',...
               'FontAngle','italic');
            set(eText(i),'Tag','Event');
         end
      end
   end
%-------------------------------------------------------------------------%
   function onRedrawButton(~,~)
      updateInterface();
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
      fig.interactivemouse;
   end % onMenuSelection

%-------------------------------------------------------------------------%
   function onArraySlider( ~, ~ )
      set(gui.ArraySlider,'Value',ceil(get(gui.ArraySlider,'Value')));
      set(gui.ArraySliderTxt,'String',...
         ['Array ' num2str(get(gui.ArraySlider,'Value')) '/'...
         num2str(numel(data.p))])
      updateInterface()
   end % onHelp
%-------------------------------------------------------------------------%
   function onStripsButton( ~, ~ )
      if data.plotS
         set(gui.MousePanButton,'Value',0);
         fig.interactivemouse('OFF');
         
         ind = get(gui.ArraySlider,'Value');
         if isa(data.p,'Segment')
            s = cell.flatten(extract(data.p,'SampledProcess','type'));
            values = s{ind}.values{1};
         else
            values = data.p(ind).values{1};
         end
         data.sd = max(nanstd(values));
         
         if get(gui.StripsButton,'Value')
            set(gui.ScaleSlider,'Value',3);
            set(gui.ScaleSliderTxt,'String','Strips separation 3 SD');
         else
            set(gui.ScaleSlider,'Value',0);
            set(gui.ScaleSliderTxt,'String','Strips separation 0 SD');
         end
         
         plotS();
      end
   end % onHelp
%-------------------------------------------------------------------------%
   function onScaleSlider( ~, ~ )
      if get(gui.StripsButton,'Value')
         set(gui.ScaleSliderTxt,'String',...
            ['Strips separation ' sprintf('%1.1f',(get(gui.ScaleSlider,'Value'))) ' SD']);
         plotS();
      else
         set(gui.ScaleSlider,'Value',0);
         set(gui.ScaleSliderTxt,'String','Strips separation 0 SD');
      end
   end % onExit

%-------------------------------------------------------------------------%
   function onExit( ~, ~ )
      % User wants to quit out of the application
      delete( gui.Window );
   end % onExit

end % EOF