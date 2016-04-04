% Probably should go through testPlotRaster first.
%
% getPsth works with cell arrays of event times. Currently, this
% function accepts cell arrays with <= 2 dimensions. In fact, you can do
% everything the function is capable of with one-dimensional cell arrays
% (columns), but the 2-d handling is for backwards compatibility, and in
% some cases, can make things a bit easier.
%
% I used to use 2-D cell arrays a lot, and the convention was the rows
% corresponded to trials and columns corresponded to neurons. That is not
% so relevant for using the function.
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3 neurons with the same number of trials
clear all
close all

import spk.*
import fig.*

% Fake spike times
spk = cell(50,3);
shift = [0 -1.5 1.5];
rate = [40 10 20];
for i = 1:length(spk)
   spk{i,1} = rand(rate(1),1) + shift(1);
   spk{i,2} = rand(rate(2),1) + shift(2);
   spk{i,3} = rand(rate(3),1) + shift(3);
end

plotRaster(spk,'grpColor',{'b' 'r' 'g'},'window',[-2 3]);

% Default rate estimates w/ 25 millisecond bins
[r,t,r_sem] = getPsth(spk,0.025);
clf
plot(t,r);

% By default, the time window is fixed by the earliest and latest spike 
% across all neurons. We can use a different window
[r,t,r_sem] = getPsth(spk,0.025,'window',[-5 5]);
clf;
plot(t,r);

% By default, estimates are created for all neurons. 
% We can select particular neurons by using colIndex 
[r,t,r_sem] = getPsth(spk,0.025,'window',[-5 5],'colIndex',[1 3]);
clf;
plot(t,r);
% Or by directly passing in a subset of spk
[r,t,r_sem] = getPsth(spk(:,[1 3]),0.025,'window',[-5 5]);
hold on; plot(t,r,'.');

%% Some examples of different rate estimates
clf;
for i = 1:5
   if i == 1
      % Very coarse binning
      tic;
      [r,t,r_sem] = getPsth(spk,0.5,'window',[-2 3]);
      toc
   elseif i == 2
      % Illustrate the shifting option for 'hist'
      [r,t,r_sem] = getPsth(spk,0.5,'window',[-2 3],'method','hist','centerHist',true);
   elseif i == 3
      % Quick density estimate, w/ default gaussian kernel using a 5 msec bandwidth
      tic;
      [r,t,r_sem] = getPsth(spk,0.005,'window',[-2 3],'method','qkde');
      toc
   elseif i == 4
      % Quick density estimate, w/ triangular kernel using 25 msec bandwidth
      [r,t,r_sem] = getPsth(spk,0.025,'window',[-2 3],'method','qkde','kernel','t');
   elseif i == 5
      % Exact density estimate, w/ gaussian kernel using 25 msec bandwidth
      tic;
      [r,t,r_sem] = getPsth(spk,0.025,'window',[-2 3],'method','kde');
      toc
   end
   subplot(5,1,i); hold on

   % True rates
   plot([-2 shift(1) shift(1) shift(1)+1 shift(1)+1 3],[0 0 rate(1) rate(1) 0 0],'b--');
   plot([-2 shift(2) shift(2) shift(2)+1 shift(2)+1 3],[0 0 rate(2) rate(2) 0 0],'r--');
   plot([-2 shift(3) shift(3) shift(3)+1 shift(3)+1 3],[0 0 rate(3) rate(3) 0 0],'g--');
   
   % Estimates
   boundedline(t,r(:,1),r_sem(:,1),'b',t,r(:,2),r_sem(:,2),'r',t,r(:,3),r_sem(:,3),'g','alpha');
   axis([-2 3 0 50]);
   drawnow;
end

%% Use rowIndex to selectively average some trials for each neuron
ind = true(size(spk));
ind(1:2:end,2) = false;
ind(1:10:end,3) = false;
[r,t] = getPsth(spk,0.025,'rowIndex',ind);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all;
close all;

import spk.*
import fig.*

% Frequently, we have spks from a single neuron that we want to plot 
% separately for different groupings of trials

% Fake spike times. SPK has a single column, so it corresponds to one
% neuron, and we have rigged things so that different subsets of trials
% have different rates, but overall, the rate looks the same
nTrials = 200;
for i = 1:4:(nTrials-1)
    spk{i,1} = rand(3,1) - 1;
    spk{i+1,1} = rand(43,1);
    spk{i+2,1} = rand(47,1) - 1;
    spk{i+3,1} = rand(7,1);
end

% Looking across all trials
figure;
h = subplot(211);
plotRaster(spk,'window',[-2 2],'handle',h);
subplot(212);
[r,t,r_sem] = getPsth(spk,0.010,'window',[-2 2],'method','qkde');
boundedline(t,r,r_sem);

% Let's split up the trials.
% The structure of the index is simple. It must be a boolean matrix. 
% It should have nTrials rows, so that it matches the length of SPK, 
% and it should have as many columns as you have 'groups', where 'groups' 
% are just arbitrary sets of trial
ind = false(nTrials,4);
ind(1:4:end,1) = true;
ind(2:4:end,2) = true;
ind(3:4:end,3) = true;
ind(4:4:end,4) = true;

% Now we can just pass the index in, using the 'rowIndex' name
figure; h = subplot(211);
plotRaster(spk,'window',[-2 2],'handle',h,'rowIndex',ind);
subplot(212);
[r,t,r_sem] = getPsth(spk,0.010,'window',[-2 2],'method','qkde','rowIndex',ind);
boundedline(t,r(:,1),r_sem(:,1),'b',...
            t,r(:,2),r_sem(:,2),'r',...
            t,r(:,3),r_sem(:,3),'g',...
            t,r(:,4),r_sem(:,4),'k');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all;
close all;

import spk.*
import fig.*

% Another frequent scenario is where trial lengths are unequal, or we want
% to only include data up to some event that may be trial specific (eg
% reaction time).

% Fake spike times for a single neuron.
% Each trial has the same format,
% a constant rate from time = 0 up to time = event1,
% when the rate jumps to a new level up to time = event2,
% when the rate jumps to a new level for 5 seconds after event2,
nTrials = 100;
for i = 1:nTrials
   event1(i,1) = rand + 0.5;
   event2(i,1) = 10*rand + 3;
   spk{i,1} = [rand(2*ceil(event1(i)),1)*event1(i);...
               event1(i) + rand(2*ceil(event2(i)*10),1)*(event2(i)-event1(i)) ;...
               event2(i)+rand(400,1)*5];
end
% Sort by the second event for visualization
[event2,I] = sort(event2);
event1 = event1(I);
spk = spk(I);

% Naive averaging of this data is misleading. Between event1 and event2,
% the firing rate on each trial should be *constant*
figure; h = subplot(211);
plotRaster(spk,'handle',h,'grpBorder',false);
plotRaster(num2cell(event1),'handle',h,'grpColor','g','markerSize',6);
plotRaster(num2cell(event2),'handle',h,'markerStyle','s','markerSize',10,'grpColor','r');
subplot(212);
[r,t,r_sem] = getPsth(spk,0.010,'method','qkde');
boundedline(t,r,r_sem,'c','alpha')
% figure; h = subplot(211);
% plotRaster(spk,'handle',h,'grpBorder',false);
% plotRaster(num2cell(event1),'handle',h,'grpColor','g','markerSize',6,'window',[0 12]);
% plotRaster(num2cell(event2),'handle',h,'markerStyle','s','markerSize',10,'grpColor','r','window',[0 12]);
% subplot(212);
% [r,t,r_sem] = getPsth(spk,10,'method','qkde','window',[0 12]);
% boundedline(t,r,r_sem,'c','alpha')

% Average up to event2 to reveal that the rate in fact flat
% Ask for data to be truncated at the event. The format for the window is 
% a numeric matrix, with two possible formats:
% 1) [1 x 2] vector indicating start and end time applying across all trials
%    this is fine when we only care about a small common window
[r,t,r_sem] = getPsth(spk,0.010,'method','qkde','window',[2 3]);
boundedline(t,r,r_sem,'k','alpha'); 
% 2) [nTrials x 2] matrix with trial specific start and end times
%    in this case, standard errors at each time point are calculated only 
%    for trials with valid windows. Hence in the example, the quality of the
%    rate estimates changes with time since we add and drop trials with the 
%    passage of time
[r,t,r_sem] = getPsth(spk,0.010,'method','qkde','window',[event1 , event2]);
boundedline(t,r,r_sem,'m','alpha')
% [r,t,r_sem] = getPsth(spk,10,'method','qkde','window',[event1 , min(event2,12)]);
% boundedline(t,r,r_sem,'m','alpha')

% We will often want to realign the spkTimes to some event of interest that
% occurs on each trial. windowTimes is a flexible function for doing this,
% and returns a cell array of event times that can be passed to plotRaster
% or getPsth
% Let's say we want to do this for event2,
% spk2 = windowTimes(spk,'offset',-event2);
% plotRaster(spk2,'grpBorder',false);

plotRaster(spk,'grpBorder',false,'offset',-event2);

% The default for alignTimes is to use a window that will include all
% spkTimes. We can restrict this, for example, say we only want to inlcude
% from event1 to 5 seconds after event2 (for each trial), with every trial
% aligned on event2
% [spk2,alignedWindow] = alignTimes(spk,'sync',event2,'window',[event1 event2+5]);
% figure; h = subplot(211);
% plotRaster(spk2,'handle',h,'grpBorder',false);

figure; h = subplot(211);
% [spk2,alignedWindow] = windowTimes(spk,'offset',-event2,'window',[event1 event2+5]);
% plotRaster(spk2,'handle',h,'grpBorder',false);

plotRaster(spk,'handle',h,'grpBorder',false,'offset',-event2,'window',[event1 event2+5]);

% Again, naive averaging is misleading, in this case not at time=0, since
% we aligned the data around that event, but near event1, which is
% different for each trial, leading to an artifactual ramp.
subplot(212);
% [r,t,r_sem] = getPsth(spk2,10,'method','qkde');
% boundedline(t,r,r_sem,'m','alpha'); axis([min(alignedWindow(:,1)) 5 0 100]);

[r,t,r_sem] = getPsth(spk,0.010,'method','qkde','offset',-event2);
boundedline(t,r,r_sem,'m','alpha'); axis([get(h,'xlim') 0 100]);

% And again, we can use a window to make a conditional average.
% alignTimes passes back an output which is the window used to align the
% spkTimes, shifted relative the sync event. Plotting this reveals that the
% rate is in fact constant between event1 and event2 (although noise 
% increases at the beginning because we lose trials).
% [r,t,r_sem] = getPsth(spk2,10,'method','qkde','window',alignedWindow);
% boundedline(t,r,r_sem,'y','alpha'); axis([min(alignedWindow(:,1)) 5 0 100]);

[r,t,r_sem] = getPsth(spk,0.010,'method','qkde','offset',-event2,'window',[event1 event2+5]);
boundedline(t,r,r_sem,'b','alpha'); axis([get(h,'xlim') 0 100]);

%% Note that above, I made a separate call to alignTimes
%%
% % You can skip the call to alignTimes if you don't need the intermediate
% % output. This works by using the 'sync' input to plotRaster or getPsth.
% % Note however, that it's the naive way of trying this does not do what you 
% % would expect,
% plotRaster(spk,'handle',h,'grpBorder',false,'sync',event2,'window',[-10 5]);
% % That's because
% % To get what we want in this example, you need to pass an additional input
% % that indicates that we don't want 
% plotRaster(spk,'handle',h,'grpBorder',false,'sync',event2,'window',[-10 5],'alignWindow',false);

% figure; h = subplot(211);
% plotRaster(spk,'handle',h,'grpBorder',false,'sync',event2,'window',[event1 event2+5]);
% subplot(212);
% [r,t,r_sem] = getPsth(spk,10,'method','qkde','sync',event2,'window',[-15 5],'alignWindow',false);
% boundedline(t,r,r_sem,'m','alpha'); axis([min(alignedWindow(:,1)) 5 0 100]);
% [r,t,r_sem] = getPsth(spk,10,'method','qkde','sync',event2,'window',[event1 event2+5]);
% boundedline(t,r,r_sem,'b','alpha'); axis([min(alignedWindow(:,1)) 5 0 100]);

% It might be useful to also see some other events shifted as well, we can
% pass these into alignTimes, 
[spk2,alignedWindow,alignedEvents] = windowTimes(spk,'offset',-event2,'window',[event1 event2+5],'events',[event1 event2]);
figure; h = subplot(211);
plotRaster(spk2,'handle',h,'grpBorder',false);
plotRaster(num2cell(alignedEvents(:,1)),'handle',h,'grpColor','g','markerSize',6,'grpBorder',false);
plotRaster(num2cell(alignedEvents(:,2)),'handle',h,'markerStyle','s','markerSize',10,'grpColor','r','grpBorder',false);
subplot(212);
[r,t,r_sem] = getPsth(spk2,0.010,'method','qkde','window',alignedWindow);
boundedline(t,r,r_sem,'b','alpha'); axis([min(alignedWindow(:,1)) 5 0 100]);

% Repeat the exercise aligning to event1 instead
[spk2,alignedWindow,alignedEvents] = windowTimes(spk,'offset',-event1,'window',[zeros(size(event1)) event2],'events',[event1 event2]);
figure; h = subplot(211);
plotRaster(spk2,'handle',h,'grpBorder',false);
plotRaster(num2cell(alignedEvents(:,1)),'handle',h,'grpColor','g','markerSize',6,'grpBorder',false);
plotRaster(num2cell(alignedEvents(:,2)),'handle',h,'markerStyle','s','markerSize',10,'grpColor','r','grpBorder',false);
subplot(212);
[r,t,r_sem] = getPsth(spk2,0.010,'method','qkde','window',alignedWindow);
boundedline(t,r,r_sem,'b','alpha'); 
axis([min(alignedWindow(:,1)) max(alignedWindow(:,2)) 0 100]);

