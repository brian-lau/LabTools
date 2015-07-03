% plotRaster                 Raster plot of event data (eg. point processes)
% 
%     [h,yOffset] = plotRaster(eventTimes,varargin)
%
%     The optional inputs are all name/value pairs. The name is a string
%     followed by the value (described below). The order of the pairs does
%     not matter, nor does the case.
%
%     INPUTS
%     eventTimes  - Cell array of eventTimes, each element containing a
%                   vector of event times. Two possible input formats,
%                   {nRows x 1} : optional rowIndex can have any number of
%                      columns
%                   {nRows x nCols} : optional rowIndex must have nCols
%                      columns
%  
%     OPTIONAL
%     handle      - Figure handle (default to new figure)
%     yOffset     - Starting trial index, useful for stacking different
%                   groups of spikes by repeatedly calling plotRaster
%     offset      - Time offset for eventTimes. Two possible input formats,
%                   scalar : offset is applied to each row of eventTimes
%                   [nRows x 1] : each row of eventTimes has unique offset
%     window      - Start and end times defining window from which to extract
%                   eventTimes. Windows are inclusive.
%                   Two possible input formats,
%                   [1 x 2] : [start end] applied to all rows of eventTimes
%                   [nRows x 2] : each row of eventTimes has unique window
%                   If not defined, default is to include all eventTimes.
%     colIndex    - [nGrps x 1] vector indicating which columns of eventTimes 
%                   to align (default all)
%                   this is a convenience parameter, the same thing can be 
%                   done by restricting eventTimes
%     windowThenOffset - Boolean for windowing before applying offset 
%                   (default true). If false, event times are offset then
%                   windowed.
%     rowIndex    - Boolean matrix indicating which rows of eventTimes to
%                   treat as separate groups. Two possible input formats,
%                   [nRows x nGrps] : This only works when eventTimes is 
%                      column-formatted. Each column of rowIndex is true for 
%                      some subset of eventTimes. Subsets are unlimited, and
%                      can overlap.
%                   [nRows x nCols] : If eventTimes has multiple columns,
%                      then rowIndex must have the same number of columns,
%                      in which case, each column of rowIndex is true from
%                      some subset of the corresponding column in
%                      eventTimes. 
%     grpBorder   - boolean for plotting lines between groups (default true)
%     grpColor    - Colors for different groups. Can be a cell array
%                   containing [R G B] values or chars like plot (eg 'r').
%                   Defaults to assigning maximally perceptually distinct
%                   colors to each group (distinguishable_colors), or if
%                   that function doesn't exist, cycles through 
%                   DefaultAxesColorOrder
%     style       - raster style
%                   'marker' (default) each spike as a symbol, much faster
%                   'tick' or 'line' plots each spike as a line
%     markerStyle - if marker style is used, this sets plot symbol (default '.')
%     markerSize  - if marker style is used, this sets symbol size (default 3pt)
%     tickHeight  - scalar (0 0.5], tick height if tick style (default 0.5)
%     tickWidth   - scalar > 0, tick width if tick style (default 1pt)
%     labelXaxis  - boolean for labelling (default true)
%     labelYaxis  - boolean for labelling (default true)
%     labelGrps   - TODO
%     skipNaN     - boolean for whether NaN trials are skipped (default true)
%
%     OUTPUTS
%     h           - Figure handle
%     yOffset     - y-value of the last trial plotted
%
%     SEE ALSO
%     alignTimes, testPlotRaster

%     $ Copyright (C) 2001-2012 Brian Lau http://www.subcortex.net/ $
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%     REVISION HISTORY:
%     brian 11.15.01 written
%     brian 10.29.03 added color argument
%     brian 06.06.07 added tind argument, and h and tind as outputs
%                    also, if binary data is entered, just finds times
%                    and calls RASTER again
%     A.Saez 01.02.08 accept color argument in the [r g b] form as well
%     brian 13.11.12 refactored using inputParser, requires R2007a, MATLAB 7.4
%                    removed optional input format for eventTimes
%                    replaced 'plot' with 'line' for tick style
%                    added numerous options for selecting, grouping, plotting

% TODO
% group labelling
% allow spike thinning option (visualization)
% useful to pass back parameter object?
% might be interesting to be able to plot grouped data, but in order of
% trial appearance?? that's not easy? Fill cell array with nans? or do some
% clever indexing of yOffset? ie, hand in index of length(nRows*nCols)
% x treatAllAsGrps option to plot each element of spk as a separate group, ignore shape of
% x spk Scratch this. Incredible pain in the ass
% add option to skip empty trials?

function [h,yOffset] = plotRaster(eventTimes,varargin)

import spk.*

if isnumeric(eventTimes)
   eventTimes = {eventTimes};
end

[nRows,nCols] = size(eventTimes);

%% Parse inputs
p = inputParser;
p.KeepUnmatched= true;
p.FunctionName = 'plotRaster';
% Passed through to alignTimes
p.addRequired('eventTimes',@(x) validateattributes(eventTimes,{'cell'},{'2d'}) );
p.addParamValue('offset',0,@(x) isnumeric(x) && (isscalar(x) || iscolumn(x)) );
p.addParamValue('colIndex',1:nCols,@(x) isnumeric(x) && all(x>0) && (max(x)<=nCols) );
p.addParamValue('window',[],@(x) validateattributes(eventTimes,{'numeric' 'cell'},{'2d'}) );
p.addParamValue('windowThenOffset',true,@islogical);
p.addParamValue('rowIndex',true(nRows,nCols),@(x) islogical(x) && (size(x,1)==nRows) );
% Specific for plotRaster
p.addParamValue('handle',[],@(x) isnumeric(x) || ishandle(x));
p.addParamValue('skipNaN',true,@islogical);
p.addParamValue('grpColor',[],@(x)( ... 
   (ischar(x) && (size(x,1)==1) && (size(x,2)==1)) ||... % single color str
   (isnumeric(x) && ((size(x,1)==1) && (size(x,2)==3))) || ... % single RGB triple
   iscell(x)) ... % cell array of str or RGB values
   );
validStyles = {'tick' 'line' 'marker'};
p.addParamValue('style','marker',@(x)any(strcmp(x,validStyles)));
p.addParamValue('markerStyle','.',@ischar);
p.addParamValue('markerSize',3,@(x)(x>0)&&isnumeric(x));
p.addParamValue('tickHeight',0.5,@(x)(x>0)&&(x<=0.5));
p.addParamValue('tickWidth',1,@(x)(x>0));
p.addParamValue('yOffset',1,@isnumeric);
p.addParamValue('labelXaxis',true,@islogical);
p.addParamValue('labelYaxis',true,@islogical);
p.addParamValue('labelGrps',false,@islogical);
p.addParamValue('grpBorder',true,@islogical);
p.parse(eventTimes,varargin{:});
plotParams = p.Unmatched; % passed through to plot

%% Setup drawing window
if isempty(p.Results.handle) || ~ishandle(p.Results.handle)
   figure;
   h = subplot(1,1,1);
else
   h = p.Results.handle;
   axes(h);
end
%set(h,'DrawMode','fast','NextPlot','replacechildren');
hold on;

%% Pass through to windowTimes, any raster-specific parameters will be ignored
[eventTimes,window] = windowTimes(eventTimes,p.Results);
[nRows,nGrps] = size(eventTimes);
grpInd = 1:nGrps;

%% Starting y-value for first trial
yOffset = p.Results.yOffset;

%% Set plot limits
if isempty(p.Results.window)
   % No explicit window, so we use a xlim that fits all the eventTimes
   if ~isempty(window)
      temp = [min(window(:,1)) max(window(:,2))];
   else
      temp = [NaN NaN]; % HACK NEEDS TEST
   end

   % Reusing handle, grow xlim to account for new data
   if ~isempty(p.Results.handle)
      xLim = get(gca,'xlim');
      xLim = [min([xLim temp(1)]) max([xLim temp(2)])];
   else
      xLim = temp;
   end
else
   if size(window,2) > 1
      xLim = [min(window(:,1)) max(window(:,2))];
   else
      xLim = window;
   end
end
try
   xlim(xLim);
catch
   xLim = [NaN NaN];
   warning('Looks like there aren''t any spikes');
end

%% Assign colors
if isempty(p.Results.grpColor)
   c = get(0,'DefaultAxesColorOrder');
   count = 1;
   for i = grpInd
      col{i} = c(count,:);
      count = mod(count,size(c,1));
      count = count + 1;
   end
elseif ischar(p.Results.grpColor)
   for i = grpInd
      col{i} = p.Results.grpColor;
   end
elseif iscell(p.Results.grpColor)
   count = 1;
   for i = grpInd
      col{i} = p.Results.grpColor{count};
      count = count + 1;
   end
elseif isnumeric(p.Results.grpColor)
   for i = grpInd
      col{i} = p.Results.grpColor;
   end
end

%% Plot

for i = grpInd % groups
   x = [];
   y = [];
   count = 1;
   for j = 1:nRows
      spk = eventTimes{j,i}(:)';
      nSpk = numel(spk);
      N = NaN(1,nSpk);
      
      if isempty(spk)
         count = count + 1;
      elseif all(isnan(spk)) && p.Results.skipNaN
      else
         if strcmp(p.Results.style,'tick')
            tempx = [spk ; spk ; N];
            tempy = [count*ones(1,nSpk)-p.Results.tickHeight ; count*ones(1,nSpk)+p.Results.tickHeight ; N];
         else
            tempx = spk;
            tempy = count*ones(1,nSpk);
         end
         x = [x ; tempx(:)];
         y = [y ; tempy(:)];
         count = count + 1;
      end
   end
   if strcmp(p.Results.style,'tick')
      line(x,yOffset+y-1,'color',col{i},'Linewidth',p.Results.tickWidth,plotParams);
   else
      plot(x,yOffset+y-1,'color',col{i},'marker',p.Results.markerStyle,...
         'linestyle','none','Markersize',p.Results.markerSize,plotParams);
   end
   yOffset = yOffset + count - 1;
   if p.Results.grpBorder
      plot(xLim, [yOffset yOffset] - p.Results.tickHeight,'-','color',col{i});
   end
end

% ylim should always include what we plotted
yLim = get(gca,'ylim');
ylim([yLim(1) yOffset+p.Results.tickHeight-1]);

%% Decorate
if p.Results.labelYaxis
   ylabel('Trials');
end
if p.Results.labelXaxis
   xlabel('Time');
end
