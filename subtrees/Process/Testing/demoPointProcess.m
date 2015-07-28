% To get some help
doc PointProcess
% Each object method has some documention
help PointProcess.raster

clear all;
%% Basic pointProcess object
p = PointProcess('times',3*rand(20,1))
%
% The properties provide access to the basic elements of a point process:
%
% window is a very important property to grasp in order to understand
% the behavior of pointProcess methods. Window can be a [1 x 2] vector that
% defines the start and end time of *interest*. This is distinct from the
% start and end time of the process (tStart and tEnd, which don't change).
% The idea of windows, is that we can define them as we need to look at
% different parts (or the whole) point process. There can be multiple,
% overlapping windows, and a number of properties are dependent on the
% window(s) set, and automatically adjusted as we change windows.

% the times property 
p.times{1}

% pointProcess objects can be defined with a specific window. Note that
% event times outside of the window passed into the contructor are *not*
% discarded. 
p = PointProcess('times',3*rand(20,1),'window',[0 1])
%
% We can check this by setting a new window for this object that overlaps
% with times we passed in, but are not in the window
p.window = [0 6]
% 
% And since we don't discard data after construction, we can get back to a
% default window (if no window was passed in during construction)
p.setInclusiveWindow()
%
% or if we want the original window passed to the contructor
p.reset()

% If you want to contruct a process with non-default tStart and tEnd times,
% you can pass these in. Event times < tStart and > tEnd will be discarded.
% This is the only time that event times are discarded.
p = PointProcess('times',3*rand(1,20),'tStart',0.5,'tEnd',2)
p.times{1}

% Note that there is an offset property as well, which allows you to
% specify a temporal shift of the windowed spike times.
% This is by default zero
p = PointProcess('times',rand(1,5))
p.offset
p.times{1}

% Changing offset shifts the windowedTimes
p.offset = 1;
p.times{1}

clear all
%% Let's put these properties together to see how things might be used
p = PointProcess('times',10*rand(1,100))
% First off, there's a method for plotting data that's handy
p.raster();

% Now let's look at the spike times through a series of windows
% First we window
winStart = 0:1:10;
window = [winStart' , winStart'+1];
p.window = window;
p.raster();

% Note that the different windows are shifted in time. This makes sense
% since all the windows share a common origin.
% It might be more useful to see all the windows aligned such that origin
% for each window was it's leading edge. We saw above how to apply an
% offset. It is also possible to specify a different offset for each window, 
% in which case we assign a vector, whose length must match the number of
% windows
p.offset = -p.window(:,1);
p.raster('window',[0 10]);

% Offsets always follow windowing, so that whenever a window is changed,
% the offsets are reapplied to times windowed without offsets
% They are additive

% Unless the window size is changed, in which case, they are reset to zero
p.window = [0 3; 3 6];
p.offset

clear all;
%% Triggered average example
% Now that you have a grasp of how windows work, let's look at a more
% realistic example. Imagine an experiment where a series of different 
% stimuli trigger different responses in a neuron. We would like to look at
% the response aligned to the onset of each different stimulus.

% Create some fake data
% Stimulus consists of 9 conditions (indexed with an integer from -4:4).
stim = unidrnd(9,1,1000);
stim = stim(:) - 5;
% Assume that a stimulus occurs every second
stimOnsets = 1:length(stim);
% For the different stimulus levels, simulate different spike rates, and
% also delay the response differentially
% Modelled after a tuning curve, with maximal response near stim=0, and
% decreasing away from stim=0.
resp = [];
for i = 1:length(stim)
   if stim(i) == 0
      % Response duration = 0.2, starting 0.1 before stim
      resp = [resp , i + 0.2*rand(1,400) - 0.1];
   elseif abs(stim(i)) == 1
      % Response duration = 0.1, starting 0.05 after stim
      resp = [resp , i + 0.05 + 0.1*rand(1,100)];
   elseif abs(stim(i)) == 2
      % Response duration = 0.1, starting 0.1 after stim
      resp = [resp , i + 0.10 + 0.1*rand(1,50)];
   else
      % Response duration = 0.1, starting 0.15 after stim
      resp = [resp , i + 0.15 + 0.1*rand(1,5)];
   end
end

% Basic plot of the data, messy, but zooming in reveals the responses
figure; hold on
stem(stimOnsets,stim,'r');
stem(resp,ones(size(resp)));

% Construct a pointProcess object
p = PointProcess('times',resp);

% The responses were constructed such that the rate was highest and fastest
% when the stimulus was near zero, and progressively less responsive and
% slower further from zero. Sorting the stim will simply allow us to see
% things better, it's not necessary.
[sortedStim,I] = sort(stim);
% We want to look at a window after each stimulus, 
window = [stimOnsets(I)' , stimOnsets(I)'+.2];
p.window = window;

% A plot without changing the offset would plot things in absolute time,
% might be interesting to see. Note that the structure is due to how we
% sorted the stimulus, which is how we sorted the windows.
raster(p)
% But it's probably more interesting to apply an offset so that the zero
% time for each window is the start of each stimulus.
p.offset = -p.window(:,1);
raster(p);
% We can do some grouping to help visualization (see plotRaster options)
raster(p,'rowIndex',[sortedStim==-2,sortedStim==-1,sortedStim==0,sortedStim==1,sortedStim==2]);

% What about shifted windows? 
%p.setInclusiveWindow();
window = [stimOnsets(I)'-0.1, stimOnsets(I)'+0.2];
p.window = window;
p.offset = -p.window(:,1) - 0.1;
raster(p)

% %% Example where there are events that define trials
% % Extended example where these events reside inside the info container
% p.window = [p.info('trial start') , p.info('trial end')];
% % How to take 500 ms window after image onset on each trial?
% p.window = repmat([0 0.1],nTrials,1);
% p.offset = [p.info('image onset')];
% p.offset = -p.window(:,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Different kinds of point process
% Spatial point process
%   The info property allows you to include arbitrary information, so you
%   could use it to create a spatial point process
% Marked point processes
%   The pointProcess class can be used for marked point processes, although
%   neuroscientists rarely use this representation, it is built in for
%   future potential.
%   The marks property can be a vector of objects (waveforms?)
p = PointProcess('times',randn(100,1),'values',rand(100,1));
stem(p.times{1},p.values{1});

%% Methods - plotting
clear all;
close all;
p = PointProcess('times',3*randn(40,1));

% Raster shows the event times in a format familiar to neuroscientists
p.raster();
% Raster accepts many options (see help for p.plotRaster). These are name/value 
% pairs that are case insensitive and can be passed in any order. This is
% particularly useful when using collections of pointProcess objects (see
% the class pointProcessCollection)
p.raster('style','line','grpColor','r');

% You can also pass figure handles in
clf;
h = subplot(311);
p.raster('style','line','grpColor','r','handle',h);
axis([-6 6 get(gca,'ylim')]);

% Note that in the previous raster plot, we only see part of the data.
% That's because we set the window property above. You can change this two
% ways. 
% 1) If you want to apply a different window for the raster plot, you can
%    pass it in as a parameter, in which case it will not be copied into
%    the object. Note that this window will override the object property
p.raster('style','line','grpColor','g','handle',subplot(312),'window',[-6 6]);
% 2) Or you can modify the object first, then call the display method
p.window = [-6 6];
p.raster('style','line','grpColor','b','handle',subplot(313));
axis([-6 6 get(gca,'ylim')]);

close all

%% Methods - manipulating properties
% We can always return the PointProcess object to its original state
p.reset()
clf;
p.raster('style','line','grpColor','r','handle',subplot(311));
axis([-15 15 get(gca,'ylim')]);
%
% Frequently we want to shift event times relative to some other time.
% This can be done using the overloaded operators. 
% Note that this will move the windows as well.
% Addition
p + 5;
p.raster('style','line','grpColor','g','handle',subplot(312));
axis([-15 15 get(gca,'ylim')]);
%
% Subtraction
p - 5;
% Note that this will move the windows as well
p.raster('style','line','grpColor','b','handle',subplot(313));
axis([-15 15 get(gca,'ylim')]);

% Repeat this with a different window setting
% Note that addition and subtraction actually change the times associated
% with the point process. If you don't want to keep in mind what you added
% and subtracted, you should reset the object before changing the window.
p.reset();
p.window = [0 5];
%
figure;
p.raster('style','line','grpColor','r','handle',subplot(311));
axis([-15 15 get(gca,'ylim')]);
p + 5;
p.raster('style','line','grpColor','g','handle',subplot(312));
axis([-15 15 get(gca,'ylim')]);
p - 5;
p.raster('style','line','grpColor','b','handle',subplot(313));
axis([-15 15 get(gca,'ylim')]);

% % There is a method for estimate the point process intensity (PSTH). This
% % can be called with all the options for getPsth. As for raster these are 
% % name/value pairs that are case insensitive and can be passed in any order. 
% close all;
% p = PointProcess('times',3*randn(150,1));
% % Plot raster
% p.raster('style','line','handle',subplot(411));
% axis([-15 15 get(gca,'ylim')]);
% % The getPsth method requires one input, which is the bandwidth of the
% % estimator in milliseconds. Without further arguments, this is just a
% % histogram estimator with bin widths = bandwidth
% [r,t] = p.getPsth(25);
% subplot(412);
% plot(t,r,'c'); 
% axis([-15 15 get(gca,'ylim')]);
% % Kernel density estimator, gaussian default
% [r,t] = p.getPsth(25,'method','qkde');
% subplot(413);
% plot(t,r,'r'); 
% axis([-15 15 get(gca,'ylim')]);
% % Kernel density estimator, different kernel (see getPsth)
% [r,t] = p.getPsth(100,'method','qkde','kernel','e');
% subplot(414);
% plot(t,r,'k'); 
% axis([-15 15 get(gca,'ylim')]);

% Example with passing window in

close all;

%% Arrays of pointProcess objects
% Most of the methods for the pointProcess class work with object arrays. 
% The utility of this will become apparant with the pointProcessCollection
% class, but here are some examples to exercise the class.

n = 50;
for i = 1:n
   p(i,1) = PointProcess('times',rand(100,1));
end

% TODO add note about column versus row ordering and how it affects method
% calls that are vectorized
%
% Don't create pointProcess arrays the follow way. 
% a(3,3) = pointProcess('times',randn(100,1));
% Single instance of times is put into last element. You can use this kind
% of call to preallocate an array object, but you always need to use a loop
% to fill in the data.

p
% Not much different, although now we have an object array. 
p.raster('handle',subplot(411));
axis([-5 5 0 n]);

% Addition to the object array adds to each element
p + 1;
p.raster('handle',subplot(412),'grpColor','m');
axis([-5 5 0 n]);

% And subtraction subtracts from each element
p - 1;
p.raster('handle',subplot(413),'grpColor','c');
axis([-5 5 0 n]);

% Vector addition and subtraction work element-wise, so that you can add or
% subtract a different scalar for each object element
p = p.reset();
p + linspace(-1,1,n);
p.raster('handle',subplot(414),'grpColor','r');
axis([-5 5 0 n]);

p = p.reset();
p - linspace(-1,1,n);
p.raster('handle',subplot(414),'grpColor','b');
axis([-5 5 0 n]);

close all;

% The equality operator is also overloaded
