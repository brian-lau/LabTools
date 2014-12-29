function ss_out = screensize(screen_number)
%screensize: return screen coordinates of multiple monitors.
 
% Version: 1.0, 26 June 2008
% Author: Douglas M. Schwarz
% Email: dmschwarz=ieee*org, dmschwarz=urgrad*rochester*edu
% Real_email = regexprep(Email,{'=','*'},{'@','.'})
 
 
persistent ss
if ~isempty(ss)
    num_screens = size(ss,1);
    if nargin == 0
        screen_number = 1:num_screens;
    end
    screen_index = min(screen_number,num_screens);
    ss_out = ss(screen_index,:);
    return
end
 
% Create an invisible figure (required for get(0,'PointerLocation') to work
% correctly on OS X).
fig = figure('Visible','off');
 
% Get initial location of mouse pointer.
mouse_loc = java.awt.MouseInfo.getPointerInfo.getLocation;
 
% Create a robot to move mouse pointer.
robot = java.awt.Robot;
 
% Get Screen Devices array.
sd = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment.getScreenDevices;
 
% Initialize screensize array.
num_screens = length(sd);
ss = zeros(num_screens,4);
 
% Loop over all Screen Devices.
for i = 1:num_screens
    % Get coordinate bounds of Screen Device.
    bounds = sd(i).getDefaultConfiguration.getBounds;
 
    % Move mouse pointer to lower left corner of this screen and get MATLAB
    % coordinates of that point.
    robot.mouseMove(bounds.x, bounds.y + bounds.height)
    pl_ll = get(0,'PointerLocation');
 
    % Move mouse pointer to upper right corner of this screen and get
    % MATLAB coordinates of that point.
    robot.mouseMove(bounds.x + bounds.width, bounds.y)
    pl_ur = get(0,'PointerLocation');
 
    % Fill in screen size array.
    ss(i,:) = [pl_ll, pl_ur - pl_ll];
end
 
num_screens = size(ss,1);
if nargin == 0
    screen_number = 1:num_screens;
end
screen_index = min(screen_number,num_screens);
ss_out = ss(screen_index,:);
 
% Return mouse pointer to initial location.
robot.mouseMove(mouse_loc.x, mouse_loc.y)
 
% Delete the figure.
delete(fig)
