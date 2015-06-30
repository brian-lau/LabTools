function varargout = processBrowser(varargin)
% PROCESSBROWSER MATLAB code for processBrowser.fig
%      PROCESSBROWSER, by itself, creates a new PROCESSBROWSER or raises the existing
%      singleton*.
%
%      H = PROCESSBROWSER returns the handle to a new PROCESSBROWSER or the handle to
%      the existing singleton*.
%
%      PROCESSBROWSER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PROCESSBROWSER.M with the given input arguments.
%
%      PROCESSBROWSER('Property','Value',...) creates a new PROCESSBROWSER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before processBrowser_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to processBrowser_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%   Copyright 2009-2013 The MathWorks Ltd.

% Edit the above text to modify the response to help processBrowser

% Last Modified by GUIDE v2.5 30-Jun-2015 01:39:47

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @processBrowser_OpeningFcn, ...
                   'gui_OutputFcn',  @processBrowser_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before processBrowser is made visible.
function processBrowser_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to processBrowser (see VARARGIN)

% Choose default command line output for processBrowser
handles.output = hObject;
% Parse data, 
handles = createData(handles,varargin{:});
% Update handles structure
guidata(hObject, handles);
creatInterface(handles)
updateInterface(hObject, eventdata, handles)

function handles = createData(handles,varargin)
data = varargin{1};
handles.plotS = 0;
handles.plotP = 0;
handles.plotE = 0;
if isa(data,'SampledProcess')
   handles.plotS = 1;
elseif isa(data,'PointProcess')
   handles.plotP = 1;
elseif isa(data,'Segment')
   % HACK, take the first, assume the rest are the same for now
   proc = cell.uniqueRows(cat(1,data.type));
   procLabels = cell.uniqueRows(cat(1,data.labels));
   if (size(proc,1) == 1) && (size(procLabels,1) == 1)
      handles.plotS = sum(strcmp(data(1).type,'SampledProcess'));
      handles.plotP = sum(strcmp(data(1).type,'PointProcess'));
   else
      error('Different processes in each Segment element not supported');
   end
end
handles.data = data;

function creatInterface(handles)
% Put a layout in the panel
g = uix.GridFlex('Parent',handles.uipanel1,'Units','Normalized',...
   'Position',[0 0 1 1],'Spacing',10);
heights = [];
if handles.plotS
   for i = 1:numel(handles.plotS)
      boxS(i) = uix.BoxPanel( 'Parent', g, 'Title', 'Sampled Process',...
         'BorderType', 'none', 'FontSize', 16, 'FontAngle', 'italic');
      % Wrapping in uicontainer lets Position work properly
      axS(i) = axes( 'Parent', uicontainer('Parent',boxS(i)), 'Position', [.075 .1 .9 .8],...
         'tickdir', 'out', 'Tag', ['Sampled Process Axis ' num2str(i)],...
         'ActivePositionProperty', 'outerposition');
      heights = [heights -1.75];
   end
else
   boxS = uix.BoxPanel( 'Parent', g, 'Title', 'Sampled Process',...
      'BorderType', 'none', 'FontSize', 16, 'FontAngle', 'italic');
   heights = [heights 0];
end
if handles.plotP
   for i = 1:numel(handles.plotP)
      boxP(i) = uix.BoxPanel( 'Parent', g, 'Title', 'Point Process',...
         'BorderType', 'none', 'FontSize', 16, 'FontAngle', 'italic');
      axP(i) = axes( 'Parent', uicontainer('Parent',boxP(i)), 'Position', [.075 .2 .9 .6],...
         'tickdir', 'out', 'Tag', ['Point Process Axis ' num2str(i)],...
         'ActivePositionProperty', 'outerposition');
      heights = [heights -1];
   end
else
   boxP = uix.BoxPanel( 'Parent', g, 'Title', 'Point Process',...
      'BorderType', 'none', 'FontSize', 16, 'FontAngle', 'italic');
   heights = [heights 0];
end

g.Heights = heights;
if exist('axP','var')
   linkaxes([axS,axP],'x');
end

set(handles.slider_array, 'Min', 1);
set(handles.slider_array, 'Max', numel(handles.data));
set(handles.slider_array, 'SliderStep', [1 5] / max(1,(numel(handles.data) - 1)));
set(handles.slider_array, 'Value', 1); % set to beginning of sequence

function updateInterface(hObject, eventdata, handles)
if handles.plotP
   plotP(handles);
end
if handles.plotS
   plotS(handles);
end

function plotS(handles)
import fig.*

strips = get(handles.button_strips,'Value');
data = handles.data;
ax = findobj(handles.uipanel1,'Tag','Sampled Process Axis 1');
axes(ax);

ind = round(get(handles.slider_array,'Value'));
ind = max(ind,1);
ind = min(ind,numel(handles.data));
set(handles.slider_array,'Value',ind);
set(handles.text1,'String',['Element ' num2str(ind)]);

if isa(data,'Segment')
   data = cell.flatten(extract(data,'SampledProcess','type'));
   values = data{ind}.values{1};
   t = data{ind}.times{1};
else
   values = data(ind).values{1};
   t = data(ind).times{1};
end

cla; hold on;
if strips
   n = size(values,2);
   sd = nanstd(values);
   sf = (0:n-1)*3*max(sd);
   plot(t,bsxfun(@plus,values,sf));
   plot(repmat([t(1) t(end)]',1,n),[sf' , sf']','color',[.7 .7 .7 .4]);
else
   plot(t,values);
end
axis tight;
interactivemouse ON;

function plotP(handles)
import fig.*

data = handles.data;
ax = findobj(handles.uipanel1,'Tag','Point Process Axis 1');
axes(ax);

ind = round(get(handles.slider_array,'Value'));
ind = max(ind,1);
ind = min(ind,numel(handles.data));
set(handles.slider_array,'Value',ind);
set(handles.text1,'String',['Element ' num2str(ind)]);

cla;
if isa(data,'Segment')
   data = cell.flatten(extract(data,'PointProcess','type'));
   raster(data{ind},'handle',ax,'style','tick');
else
   values = data(ind).values{1};
   t = data(ind).times{1};
end

% --- Outputs from this function are returned to the command line.
function varargout = processBrowser_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in button_strips.
function button_strips_Callback(hObject, eventdata, handles)
updateInterface(hObject, eventdata, handles)


% --- Executes on slider movement.
function slider_array_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
updateInterface(hObject, eventdata, handles)


% --- Executes during object creation, after setting all properties.
function slider_array_CreateFcn(hObject, eventdata, handles)
% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
