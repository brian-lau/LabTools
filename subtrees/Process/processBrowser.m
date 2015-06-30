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

%
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
   handles.plotS = sum(strcmp(data(1).type,'SampledProcess'));
   handles.plotP = sum(strcmp(data(1).type,'PointProcess'));
end
handles.data = data;

% Update handles structure
guidata(hObject, handles);

% Put a layout in the panel
g = uix.GridFlex( 'Parent', handles.uipanel1, ...
    'Units', 'Normalized', 'Position', [0 0 1 1], ...
    'Spacing', 10 );
box1 = uix.BoxPanel( 'Parent', g, 'Title', 'Sampled Process',...
   'BorderType', 'none', 'FontSize', 20, 'FontAngle', 'italic');
axes1 = axes( 'Parent', uicontainer('Parent',box1), 'Position', [.075 .1 .9 .8],...
   'tickdir', 'out', 'Tag', 'Sampled Process Axes', 'ActivePositionProperty', 'outerposition');
% axes1 = axes( 'Parent', box1, 'ActivePositionProperty', 'outerposition',...
%    'tickdir', 'out', 'Tag', 'Sampled Process Axes');
box2 = uix.BoxPanel( 'Parent', g, 'Title', 'Point Process',...
   'BorderType', 'none', 'FontSize', 20, 'FontAngle', 'italic');
axes2 = axes( 'Parent', uicontainer('Parent',box2), 'Position', [.075 .25 .9 .6],...
   'tickdir', 'out', 'Tag', 'Point Process Axes', 'ActivePositionProperty', 'outerposition');
% axes2 = axes( 'Parent', box2, 'ActivePositionProperty', 'outerposition',...
%    'tickdir', 'out', 'Tag', 'Point Process Axes');
g.Heights = [-1.75 -1];

linkaxes([axes1,axes2],'x');

set(handles.slider_array,'Value',1);
set(handles.slider_array,'Max',numel(data));

updateInterface(hObject, eventdata, handles)
% UIWAIT makes processBrowser wait for user response (see UIRESUME)
% uiwait(handles.figure1);

function updateInterface(hObject, eventdata, handles)

plotS(handles)

function plotS(handles)
import fig.*

strips = get(handles.button_strips,'Value');
data = handles.data;
ax = findobj(handles.uipanel1,'Tag','Sampled Process Axes');
axes(ax);

ind = round(get(handles.slider_array,'Value'));
ind = max(ind,1);
ind = min(ind,numel(handles.data));
set(handles.slider_array,'Value',ind);

cla;
hold on;
if strips
   temp = data(ind).values{1};
   n = size(temp,2);
   sd = nanstd(temp);
   sf = (0:n-1)*3*max(sd);
   plot(data(ind).times{1},bsxfun(@plus,temp,sf));
   plot([data(ind).times{1}(1) data(ind).times{1}(end)],[sf' , sf'],'color',[.7 .7 .7 .4]);
   axis tight;
else
   plot(data(ind).times{1},data(ind).values{1});
   axis tight;
end
interactivemouse ON;

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
