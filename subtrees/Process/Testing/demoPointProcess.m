% To get some help
doc PointProcess
% Each object method has some documention
help PointProcess.raster

clear all;

clear all;
%% Basic pointProcess object
spk = PointProcess('times',3*rand(20,1))
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
spk.times{1}

% pointProcess objects can be defined with a specific window. Note that
% event times outside of the window passed into the contructor are *not*
% discarded. 
spk = PointProcess('times',3*rand(20,1),'window',[0 1])
%
% We can check this by setting a new window for this object that overlaps
% with times we passed in, but are not in the window
spk.window = [0 6]
% 
% And since we don't discard data after construction, we can get back to a
% default window (if no window was passed in during construction)
spk.setInclusiveWindow()
%
% or if we want the original window passed to the contructor
spk.reset()

% If you want to contruct a process with non-default tStart and tEnd times,
% you can pass these in. Event times < tStart and > tEnd will be discarded.
% This is the only time that event times are discarded.
spk = PointProcess('times',3*rand(1,20),'tStart',0.5,'tEnd',2)
spk.times{1}

% Note that there is an offset property as well, which allows you to
% specify a temporal shift of the windowed spike times.
% This is by default zero
spk = PointProcess('times',rand(1,5))
spk.offset
spk.times{1}

% Changing offset shifts the windowedTimes
spk.offset = 1;
spk.times{1}

clear all
%% Let's put these properties together to see how things might start getting
% useful.
spk = PointProcess('times',10*rand(1,100))
% First off, there's a method for plotting data that's handy
spk.raster

% You might not see anything, but if you look closely, there are tiny dots
% at the event times. They're tiny because the default is set to plot huge
% amounts of event times. 
% This is easy to change. The raster calls plotRaster to do all the work,
% so all the options available in that function can be passed in here.
help spk.plotRaster
spk.raster('style','line')

% Now let's look at the spike times through a series of windows
% First we window
winStart = 0:1:10;
window = [winStart' , winStart'+1];
spk.window = window;
spk.raster('style','line')

% Note that the different windows are shifted in time. This makes sense
% since all the windows share a common origin.
% It might be more useful to see all the windows aligned such that origin
% for each window was it's leading edge. We saw above how to apply an
% offset. It is also possible to specify a different offset for each window, 
% in which case we assign a vector, whose length must match the number of
% windows
spk.offset = -spk.window(:,1);
spk.raster('window',[0 10],'style','line');

% Offsets always follow windowing, so that whenever a window is changed,
% the offsets are reset to zero
% Moreover new offsets replace old offsets (ie, they are not additive).
spk.window = [0 3; 3 6];
spk.offset

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
stem(stimOnsets,stim,'r')
stem(resp,ones(size(resp)))

% Construct a pointProcess object
spk = PointProcess('times',resp);

% The responses were constructed such that the rate was highest and fastest
% when the stimulus was near zero, and progressively less responsive and
% slower further from zero. Sorting the stim will simply allow us to see
% things better, it's not necessary.
[sortedStim,I] = sort(stim);
% We want to look at a window after each stimulus, 
window = [stimOnsets(I)' , stimOnsets(I)'+.2];
spk.window = window;

% A plot without changing the offset would plot things in absolute time,
% might be interesting to see. Note that the structure is due to how we
% sorted the stimulus, which is how we sorted the windows.
raster(spk)
% But it's probably more interesting to apply an offset so that the zero
% time for each window is the start of each stimulus.
spk.offset = -spk.window(:,1);
raster(spk)
% We can do some grouping to help visualization (see plotRaster options)
raster(spk,'rowIndex',[sortedStim==-2,sortedStim==-1,sortedStim==0,sortedStim==1,sortedStim==2])

% What about shifted windows? 
spk.setInclusiveWindow();
window = [stimOnsets(I)'-0.1, stimOnsets(I)'+0.2];
spk.window = window;
spk.offset = -spk.window(:,1) - 0.1;
raster(spk)

% %% Example where there are events that define trials
% % Extended example where these events reside inside the info container
% spk.window = [spk.info('trial start') , spk.info('trial end')];
% % How to take 500 ms window after image onset on each trial?
% spk.window = repmat([0 0.1],nTrials,1);
% spk.offset = [spk.info('image onset')];
% spk.offset = -spk.window(:,1);

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
spk = PointProcess('times',randn(100,1),'values',rand(100,1));
stem(spk.times{1},spk.values{1});

%% Methods - plotting
clear all;
close all;
spk = PointProcess('times',3*randn(40,1));

% Raster shows the event times in a format familiar to neuroscientists
spk.raster();
% Raster accepts many options (see help for spk.plotRaster). These are name/value 
% pairs that are case insensitive and can be passed in any order. This is
% particularly useful when using collections of pointProcess objects (see
% the class pointProcessCollection)
spk.raster('style','line','grpColor','r');

% You can also pass figure handles in
clf;
h = subplot(311);
spk.raster('style','line','grpColor','r','handle',h);
axis([-6 6 get(gca,'ylim')]);

% Note that in the previous raster plot, we only see part of the data.
% That's because we set the window property above. You can change this two
% ways. 
% 1) If you want to apply a different window for the raster plot, you can
%    pass it in as a parameter, in which case it will not be copied into
%    the object. Note that this window will override the object property
spk.raster('style','line','grpColor','g','handle',subplot(312),'window',[-6 6]);
% 2) Or you can modify the object first, then call the display method
spk.window = [-6 6];
spk.raster('style','line','grpColor','b','handle',subplot(313));
axis([-6 6 get(gca,'ylim')]);

close all

%% Methods - manipulating properties
% We can always return the PointProcess object to its original state
spk = spk.reset()
clf;
spk.raster('style','line','grpColor','r','handle',subplot(311));
axis([-15 15 get(gca,'ylim')]);
%
% Frequently we want to shift event times relative to some other time.
% This can be done using the overloaded operators. 
% Note that this will move the windows as well.
% Addition
spk + 5;
spk.raster('style','line','grpColor','g','handle',subplot(312));
axis([-15 15 get(gca,'ylim')]);
%
% Subtraction
spk - 5;
% Note that this will move the windows as well
spk.raster('style','line','grpColor','b','handle',subplot(313));
axis([-15 15 get(gca,'ylim')]);

% Repeat this with a different window setting
% Note that addition and subtraction actually change the times associated
% with the point process. If you don't want to keep in mind what you added
% and subtracted, you should reset the object before changing the window.
spk.reset();
spk.window = [0 5];
%
figure;
spk.raster('style','line','grpColor','r','handle',subplot(311));
axis([-15 15 get(gca,'ylim')]);
spk + 5;
spk.raster('style','line','grpColor','g','handle',subplot(312));
axis([-15 15 get(gca,'ylim')]);
spk - 5;
spk.raster('style','line','grpColor','b','handle',subplot(313));
axis([-15 15 get(gca,'ylim')]);

% % There is a method for estimate the point process intensity (PSTH). This
% % can be called with all the options for getPsth. As for raster these are 
% % name/value pairs that are case insensitive and can be passed in any order. 
% close all;
% spk = PointProcess('times',3*randn(150,1));
% % Plot raster
% spk.raster('style','line','handle',subplot(411));
% axis([-15 15 get(gca,'ylim')]);
% % The getPsth method requires one input, which is the bandwidth of the
% % estimator in milliseconds. Without further arguments, this is just a
% % histogram estimator with bin widths = bandwidth
% [r,t] = spk.getPsth(25);
% subplot(412);
% plot(t,r,'c'); 
% axis([-15 15 get(gca,'ylim')]);
% % Kernel density estimator, gaussian default
% [r,t] = spk.getPsth(25,'method','qkde');
% subplot(413);
% plot(t,r,'r'); 
% axis([-15 15 get(gca,'ylim')]);
% % Kernel density estimator, different kernel (see getPsth)
% [r,t] = spk.getPsth(100,'method','qkde','kernel','e');
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
   spk(i,1) = PointProcess('times',rand(100,1));
end

% TODO add note about column versus row ordering and how it affects method
% calls that are vectorized
%
% Don't create pointProcess arrays the follow way. 
% a(3,3) = pointProcess('times',randn(100,1));
% Single instance of times is put into last element. You can use this kind
% of call to preallocate an array object, but you always need to use a loop
% to fill in the data.

spk
% Not much different, although now we have an object array. 
spk.raster('handle',subplot(411));
axis([-5 5 0 n]);

% Addition to the object array adds to each element
spk + 1;
spk.raster('handle',subplot(412),'grpColor','m');
axis([-5 5 0 n]);

% And subtraction subtracts from each element
spk - 1;
spk.raster('handle',subplot(413),'grpColor','c');
axis([-5 5 0 n]);

% Vector addition and subtraction work element-wise, so that you can add or
% subtract a different scalar for each object element
spk = spk.reset();
spk + linspace(-1,1,n);
spk.raster('handle',subplot(414),'grpColor','r');
axis([-5 5 0 n]);

close all;

% The equality operator is also overloaded

% So we can put together arrays of pointProcess objects, and manipulate
% them. Importantly, all the elements of the object array share the same
% timebase. How should we manage things when we want different timebases
% for different elements? Imagine recording the spiking activity from one
% neuron. Say there are two events of interest, and we want to examine the
% activity of the neuron, aligned to each event. Couple ways to do this:
%
% 1) Maintain absolute time
% If we put the data into one object, then we can use window property to 
% shift and examine the point process at different times (eg., get the 
% count property after setting the window around event1 or event2). The
% problem is that there is only one window per object, so you have to loop
% for each event.
%
% 2) Move to relative time
% We could put the data into an object array. For example, put the spike
% times surrounding event1 into pointProcess(1) and the spike times
% surrounding event2 into pointProcess(2). Note that when we do this, we 
% would shift the spike times relative to a new zero (eg. the events). 
% Then using the setWindow method, we can return count as a comma-separated
% list.
%
% For this simple example, it's not clear which is better, and an argument
% could even be made for adding methods to the pointProcess class that
% allow you to return vector counts. 
%
% But what if we recorded from multiple neurons? By necessity, each neuron
% needs to be defined as a separate pointProcess object. These could be
% concatonated as above, but you have to do your own bookkeeping. 
% For example, if I shifted the spike times or changed the window property 
% for one neuron, did I remember to do it for the other neurons? What about
% which neurons to include in a particular analysis?
%
% What about when we recorded from different neurons at different times but
% want to analyze them relative to some event?
% 
% One possibility is to just use arrays of pointProcess objects.
% 
%          neuron1             neuron2           ...     neuron N
% trial 1  pointProcess(1,1)   pointProcess(1,2)         pointProcess(1,N)
% trial 2  pointProcess(2,1)   pointProcess(2,2)         pointProcess(2,N)
% trial 3  pointProcess(3,1)   pointProcess(3,2)         pointProcess(3,N)
%    .
% trian T  pointProcess(T,1)   pointProcess(T,2)         pointProcess(T,N)
%
% Then with logical indexing you could extract what you wanted and do
% specific analyses on a subset of data. One problem is if neural data for
% some neurons only exists on some trials, then you are left with empty
% elements in the object array. Not a huge problem, but all methods need to
% manage this possibility. Alternatively, you could arrange as a cell
% array, and leave empty those elements where data is missing (this is
% ugly...).
%
% Note that the above arrangement requires the user to enforce rules about
% accessing the object array. The pointProcess class does not explicitly
% distinguish between pointProcess(1,1) and pointProcess(T,1). There is a
% property tAbs that can be used to track this, but it seems sensible to 
% collect pointProcess objects together with some methods to manage the 
% bookkeeping, or at least to enforce sensible methods.
%
% But what differentiates a collection object from simply an array of
% pointProcess objects?
%
% Enforcing common window? No, imagine analysis where each neuron responds
% at a different time. Want neuron specific windows
%
% Selective neuron analysis. No, easy to do with logical indices into
% pointProcess array

% What are the kinds of things we want to do with data?
% 
% return data aligned to some event within some window of interest
% be able to do with selectively
%   by name
%   by some element of info
