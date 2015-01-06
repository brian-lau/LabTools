% plotRaster works with cell arrays of event times. Currently, this
% function accepts cell arrays with <= 2 dimensions. In fact, you can do
% everything the function is capable of with one-dimensional cell arrays
% (columns), but the 2-d handling is for backwards compatibility, and in
% some cases, can make things a bit easier.
%
% I used to use 2-D cell arrays a lot, and the convention was the rows
% corresponded to trials and columns corresponded to neurons. That is not
% so relevant for using the function, but it explains the default way color
% is applied to the raster plot.
%
% There are more examples in testGetPsth.mtest

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3 neurons with the same number of trials
clear all
close all

tic;
% generate some fake spikes
spk = cell(100,3);
shift = [0 -1.5 1.5];
rate = [100 10 50];
for i = 1:length(spk)
   spk{i,1} = rand(rate(1),1) + shift(1);
   spk{i,2} = rand(rate(2),1) + shift(2);
   spk{i,3} = rand(rate(3),1) + shift(3);
end

%% Default is to plot each column of spk in a different color
plotRaster(spk);

%% Assign different colors to each spk
plotRaster(spk,'grpColor',{'b' [0 .75 0] 'k'});

%% Plotting a subset of the spks
%plotRaster(spk,'colIndex',[1 3]);
plotRaster(spk(:,[1 3]));

%% No borders between groups
plotRaster(spk,'grpBorder',false);

%% Plot subset, and force all the same color, two ways you can do this
plotRaster(spk,'colIndex',[1 2],'grpColor','b');
plotRaster(spk(:,[1 2]),'grpColor','b');

%% Axis limits default to include all spks, change this using 'window'
plotRaster(spk,'window',[-3 3]);
plotRaster(spk,'window',[-1 2]);

%% Plot properties can be applied
% Except for 'grpColor', these apply to all groups. 
% To plot different symbols for different events, call RASTER
% repeatedly (see example below)
%
% again, two ways to do this
plotRaster(spk,'colIndex',2,'grpColor','m','markerstyle','o','markerfacecolor','c','markersize',5);
plotRaster(spk(:,2),'grpColor','m','markerstyle','o','markerfacecolor','c','markersize',5);
% 
plotRaster(spk,'grpColor',{'b' [0 .75 0] 'k'},'style','marker','markerstyle','x','markersize',5);

%% You can plot spikes as tick marks, but this is much slower
plotRaster(spk,'style','line','grpColor',{'b' [0 .75 0] [0.7 0.7 0.7]});

%% You can pass a plot handle 
figure;
h1 = subplot(311);
plotRaster(spk(:,1),'handle',h1,'grpColor','r','window',[-3 3]);
h2 = subplot(312);
plotRaster(spk(:,2),'handle',h2,'grpColor','b','window',[-3 3]);
h3 = subplot(313);
plotRaster(spk(:,3),'handle',h3,'grpColor','g','window',[-3 3]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all;
close all;
% Frequently, we have spks from a single neuron that we want to either
% 1) plot with some other relevant events, or
% 2) plot separately for different groupings of trials 

% Create some spk data for a single neuron truncated on some event
nTrials = 1000;
spk = cell(nTrials,1);
for i = 1:length(spk)
   event(i,1) = max(0.5,10*rand);
   spk{i,1} = rand(10,1)*event(i);
end
[event,I] = sort(event);
spk = spk(I);

%% Plotting events along with spikes 
% Default raster, returning the figure handle
h = plotRaster(spk);
% We can plot some events that happen on each trial by passing the figure 
% handle back to PLOTRASTER with different data. This works by just treating
% the events as spks (hence the call to num2cell), with different plot styling
plotRaster(num2cell(event),'handle',h,'markerStyle','s','markerSize',10,'grpColor','r');
% And we can repeat with multiple events
plotRaster(num2cell(event-.5),'handle',h,'markerStyle','v','markerSize',5,'grpColor','g');

%% Plotting different groupings of the same data
% We can plot subsets of trials for a neuron by using the 'rowIndex' 
% parameter to create different groups of trials
ind = [event<5 , event>=5]; % boolean defining two groupings of the data
h = plotRaster(spk,'rowIndex',ind);
% Again, we can pass the figure handle back to RASTER to overlay different 
% data on the same plot. Note that I turn off the grpBorder, or else the
% original grpBorder will be plotted over by the second call.
plotRaster(num2cell(event),'rowIndex',ind,'handle',h,'markerStyle','s',...
   'markerSize',10,'grpColor',{'c' 'm'},'grpBorder',false);

% Check that above works with explicit window
ind = [event<5 , event>=5]; % boolean defining two groupings of the data
h = plotRaster(spk,'rowIndex',ind,'window',[-1 5]);
plotRaster(num2cell(event),'rowIndex',ind,'handle',h,'markerStyle','s',...
   'markerSize',10,'grpColor',{'c' 'm'},'grpBorder',false,'window',[-1 5]);
% Note that another call without an explicit window will grow the xlimit to
% make sure all data currently passed in is in the plot. Note however, that
% while growing the window automatically allowed plotting the full range in
% the second call of raster, data in the first call is restricted to the
% window passed in with the first call.
% Always call with explicit windows if you don't want this to happen.
plotRaster(num2cell(event-.5),'handle',h,'markerStyle','v','markerSize',5,'grpColor','g');

%% Different way to plot groupings of the same data
% Sometimes it's useful to build plots by calling PLOTRASTER repeatedly, 
% for example, if RASTER is called within a loop 
ind = event<5;
[h,yOffset] = plotRaster(spk(ind),'grpColor','c');
plotRaster(num2cell(event(ind)),'handle',h,'markerStyle','s','markerSize',10,'grpColor','c');
ind = event>=5;
plotRaster(spk(ind),'handle',h,'grpColor','m','yOffset',yOffset);
plotRaster(num2cell(event(ind)),'handle',h,'yOffset',yOffset,'markerStyle','s','markerSize',10,'grpColor','m');

%% Check auto color cycling (will take awhile)
% If spk has one column, it's possible to pass rowIndex with multiple
% columns, in which case, each as treated as a separate group
plotRaster(spk,'rowIndex',repmat(ind,1,10));

% We can also transpose spk, since each column is treated as a separate
% group. Pretend we have 1 trial for 200 neurons!
plotRaster(spk(1:100)','grpBorder',false,'style','tick');

close all;

% More examples in testGetPsth.m

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% More testing
if 0
   %% Bad required inputs, show throw input validation error
   try
      plotRaster([]);
   catch
   end
   
   %% No real data
   plotRaster({[] []});
end
toc