function Annotate()
%demoBrowser: an example of using layouts to build a user interface
%
%   demoBrowser() opens a simple GUI that allows several of MATLAB's
%   built-in demos to be viewed. It aims to demonstrate how multiple
%   layouts can be used to create a good-looking user interface that
%   retains the correct proportions when resized. It also shows how to
%   hook-up callbacks to interpret user interaction.
%
%   See also: <a href="matlab:doc Layouts">Layouts</a>

%   Copyright 2010-2013 The MathWorks, Inc.

% Data is shared between all child functions by declaring the variables
% here (they become global to the function). We keep things tidy by putting
% all GUI stuff in one structure and all data stuff in another. As the app
% grows, we might consider making these objects rather than structures.
data = createData();
gui = createInterface( data.Files );

% % Now update the GUI with the current data
% updateInterface();
% redrawDemo();

% Explicitly call the demo display so that it gets included if we deploy
displayEndOfDemoMessage('')

%-------------------------------------------------------------------------%
   function data = createData()
      d = dir('*.mat');
      files = {{d.name}'};
      selection = [];
      
      data = struct( ...
         'Directory',pwd, ...
         'Files', files, ...
         'Selection', selection );
   end % createData

%-------------------------------------------------------------------------%
   function gui = createInterface( files )
      % Create the user interface for the application and return a
      % structure of handles for global use.
      gui = struct();
      % Open a window and add some menus
      gui.Window = figure( ...
         'Name', 'Artifact annotater', ...
         'NumberTitle', 'off', ...
         'MenuBar', 'none', ...
         'Toolbar', 'none', ...
         'HandleVisibility', 'off' );
      
      % Arrange the main interface
      mainLayout = uix.HBoxFlex( 'Parent', gui.Window, 'Spacing', 3 );
      
      % + Create the panels
      controlPanel = uix.BoxPanel( ...
         'Parent', mainLayout, ...
         'Title', 'Select a file:' );
      gui.ViewPanel = uix.BoxPanel( ...
         'Parent', mainLayout, ...
         'Title', 'Viewing: ???', ...
         'HelpFcn', @onAnnotate );
      gui.ViewContainer = uicontainer( ...
         'Parent', gui.ViewPanel );
      
      % + Adjust the main layout
      set( mainLayout, 'Widths', [350,-2]  );
      
      % + Create the controls
      controlLayout = uix.VBox( 'Parent', controlPanel, ...
         'Padding', 3, 'Spacing', 3 );
      gui.ListBox = uicontrol( 'Style', 'list', ...
         'BackgroundColor', 'w', ...
         'Parent', controlLayout, ...
         'String', files(:), ...
         'Min',0,...
         'Max',numel(data.Files),...
         'Value', data.Selection, ...
         'Callback', @onListSelection);
      gui.VariableList = uicontrol( 'Style', 'list', ...
         'BackgroundColor', 'w', 'Min', 0, 'Max', 10, 'Value', [], ...
         'Parent', controlLayout);
      gui.AnnotateButton = uicontrol( 'Style', 'PushButton', ...
         'Parent', controlLayout, ...
         'String', 'Annotate selection', ...
         'Callback', @onAnnotate );
      gui.ExportButton = uicontrol( 'Style', 'PushButton', ...
         'Parent', controlLayout, ...
         'String', 'Export to workspace', ...
         'Callback', @onExport );
      gui.SaveButton = uicontrol( 'Style', 'PushButton', ...
         'Parent', controlLayout, ...
         'String', 'Save', ...
         'Callback', @onSave );
      set( controlLayout, 'Heights', [-2 -.75 40 40 40] ); % Make the list fill the space
      
      % + Create the view
      p = gui.ViewContainer;
      gui.ViewAxes = axes( 'Parent', p );
      
      
   end % createInterface

%-------------------------------------------------------------------------%
   function onListSelection( src, ~ )
      % Blank variable listing
      gui.VariableList.String = '';
      gui.ViewPanel.Title = '';
      clearAxes();
      
      oldpointer = get(gui.Window, 'pointer');
      set(gui.Window, 'pointer', 'watch');
      drawnow;
      
      % User selected a demo from the list - update "data" and refresh
      data.Selection = get(gui.ListBox, 'Value' );
      file = data.Files{data.Selection};
      info = whos('-file',file);
      
      for i = 1:length(info)
         str{i} = [info(i).name ' - ' mat2str(info(i).size) ' - ' info(i).class];
      end
      gui.VariableList.String = str;
      set(gui.Window, 'pointer',oldpointer);
   end % onListSelection

%-------------------------------------------------------------------------%
   function onAnnotate( src, ~ )
      oldpointer = get(gui.Window, 'pointer');
      set(gui.Window, 'pointer', 'watch');
      drawnow;
      
      % User selected a demo from the list - update "data" and refresh
      data.Selection = get(gui.ListBox, 'Value' );
      data.data = [];
      data.artifacts = [];
      
      file = data.Files{data.Selection};
      s = load(file);      
      set(gui.Window, 'pointer',oldpointer);
      
      data.data = s.data;
      
      if isfield(s,'artifacts')
         data.artifacts = s.artifacts;
      end
      
      if ~isempty(data.artifacts)
         data.artifacts = annotate(s.data,gui.ViewAxes,data.artifacts);
      else
         data.artifacts = annotate(s.data,gui.ViewAxes);
      end
      
      gui.ViewPanel.Title = file;
   end % onAnnotate

%-------------------------------------------------------------------------%
   function onExport( src, ~ )
      assignin('base','data',copy(data.data));
      assignin('base','artifacts',copy(data.artifacts.fix));
   end

%-------------------------------------------------------------------------%
   function onSave( src, ~ )
      filename = data.Files{data.Selection};
      [filename, pathname] = uiputfile('*.mat',...
         'Save as',filename);
      savestruct.data = copy(data.data);
      savestruct.artifacts = copy(data.artifacts.fix);
      save(fullfile(pathname,filename),'-struct','savestruct');
      
      updateFilelist();
   end

   function updateFilelist()
      filename = data.Files{data.Selection};
      d = dir('*.mat');
      data.Files = {d.name}';
      ind = strcmp(data.Files,filename);
      data.Selection = find(ind);    
      
      gui.ListBox.String = data.Files(:);
      gui.ListBox.Value = data.Selection;
   end

%-------------------------------------------------------------------------%
   function clearAxes()
      cla(gui.ViewAxes);
      
      % Clear contextmenus associated with axes
      h = ancestor(gui.ViewAxes,'Figure');
      delete(findobj(h,'Type','uicontextmenu'));
      try
         delete(findobj(h,'Tag','ArraySlider'));
         delete(findobj(h,'Tag','ArraySliderTxt'));
      end
      delete(findobj(h,'Tag','RangeSlider'));
      delete(findobj(h,'Tag','LineScaleSlider'));
   end

%-------------------------------------------------------------------------%
%    function onExit( ~, ~ )
%       % User wants to quit out of the application
%       delete( gui.Window );
%    end % onExit

end % EOF