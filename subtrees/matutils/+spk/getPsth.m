% getPsth                    Estimate marginal intensity of point process
% 
%     [r,t,r_sem,count,reps] = getPsth(eventTimes,bw,varargin)
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
%     bw          - bandwidth parameter to estimation method. BW units should
%                   match eventTimes units. Ie, if eventTimes are in SECONDS
%                   bw should be in SECONDS.
%  
%     OPTIONAL
%     dt          - Stepsize for the underlying binning grid. The units of 
%                   should match the units of eventTimes and bw (default=.001)
%                   Note that it is possible to miss spikes at the right 
%                   window edge since the stepsize dt may or may not include 
%                   the actual right window edge. This is usually not a
%                   problem since you will lose spikes in the edge window
%                   falling into a bin of < dt width. You could decrease dt
%                   but it probably makes more sense to increase the window
%     method      - 'hist': histogram (default)
%                   'qkde': "quick-n-dirty" kernel density estimator using 
%                           convolution w/ a finite kernel.
%                   'kde' : exact kernel density estimation using ksdensity
%                   'bars': Bayesian Adaptive Regression Splines (BARS)
%     kernel      - For 'qkde' specifies kernel type, 
%                     Gaussian (default) : 'g' | 'gauss' | 'gaussian' | 'normal'
%                             Triangular : 't' | 'tria' | 'triangle'
%                           Epanechnikov : 'e' | 'epan' | 'epanechnikov'
%                            Exponential : 'exp' | 'exponential'
%                                 Boxcar : 'b' | 'box' | 'boxcar'
%                   For 'kde' specifies kernel type,
%                     Gaussian (default) : 'normal'
%                             Triangular : 'triangle'
%                           Epanechnikov : 'epanechnikov'
%                                 Boxcar : 'box'
%     centerHist  - boolean 'hist' method (default false)
%                   Indicates whether to shift time vector to histogram bin 
%                   centers, otherwise time matches the leading edge of bin
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
%
%     OUTPUTS
%     r          - [nBins x nGrps] mean rate
%     t          - [nBins x 1] time vector
%     r_sem      - [nBins x nGrps] standard error of mean rate
%     count      - [nBins x 1] vector of # of valid trials per time point
%     reps       - [nBins x nRows x nGrps] rate estimates for individual trials
%                   NaNs replace all elements outside of window
%     varargout  - Holds outputs from extra parameters to ksdensity
%
%     SEE ALSO
%     alignTimes, plotRaster, windowPsth, testGetPsth

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
%     brian 11.00.01 written
%     brian 02.15.02 added ISI estimator
%     brian 04.18.06 added QKDE estimator
%     brian 05.01.06 outputs individual rate estimates
%     brian 02.27.07 cleaned up, removed KDE & AKDE estimators
%                    everything works with spike times in SECONDS now
%     brian 11.11.12 refactor
%                    removed ISI estimator, r_std output
%                    centering option for 'hist'
%                    optional trial-specific windows

% TODO
% x This should automatically skipNans, but check
% remove unique
% add bars
% for methods 'hist' and 'qkde' or 'kde', if we don't require the
% calculation of reps (ie, we don't use a window, and we don't need sem),
% then perhaps we should just collapse of nRows? should be much faster?
%  This is also the case for barsP, which only works for pooled data
% check that row or column arrays in eventTimes work

% automatic bw selection for kde methods:
% http://www.mathworks.com/matlabcentral/fileexchange/14034-kernel-density-estimator
% http://www.mathworks.com/matlabcentral/fileexchange/24959-kernel-density-estimation
% add locfit?

function [r,t,r_sem,count,reps] = getPsth(eventTimes,bw,varargin)

import spk.*

if isnumeric(eventTimes)
   eventTimes = {eventTimes};
end

[nRows,nCols] = size(eventTimes);

%% Parse inputs
p = inputParser;
p.KeepUnmatched= true; % ignore unknown parameters doesn't work
p.FunctionName = 'getPsth';
% Passed through to alignTimes
p.addRequired('eventTimes',@(x) validateattributes(eventTimes,{'cell'},{'2d'}) );
p.addParamValue('offset',0,@(x) isnumeric(x) && (isscalar(x) || iscolumn(x)) );
p.addParamValue('colIndex',1:nCols,@(x) isnumeric(x) && all(x>0) && (max(x)<=nCols) );
p.addParamValue('window',[],@(x) validateattributes(eventTimes,{'numeric' 'cell'},{'2d'}) );
p.addParamValue('windowThenOffset',true,@islogical);
p.addParamValue('rowIndex',true(nRows,nCols),@(x) islogical(x) && (size(x,1)==nRows) );
% Specific for getPsth
p.addRequired('bw',@(x) isnumeric(x) && ismatrix(x));
p.addParamValue('dt',0.001,@(x) isnumeric(x) && isscalar(x)); % NEED VALIDATOR
validMethods = {'hist' 'qkde' 'kde'};
p.addParamValue('method','hist',@(x) any(strcmp(x,validMethods)));
validKernels = {'t' 'tria' 'triangle' 'e' 'epan' 'epanechnikov' ...
   'b' 'box' 'boxcar' 'g' 'gauss' 'gaussian' 'normal' 'exp' 'exponential'};
p.addParamValue('kernel','normal',@(x) any(strcmp(x,validKernels)));
p.addParamValue('centerHist',false,@islogical);
p.parse(eventTimes,bw,varargin{:});

%% Pass through to windowTimes, any psth-specific parameters will be ignored
[eventTimes,window] = windowTimes(eventTimes,p.Results);
[nRows,nGrps] = size(eventTimes);
grpInd = 1:nGrps;

%% Set up bandwidth
% should we allow bw to be different? no, complicates output for hist since
% each time vector will have different lengths?
% however, for all the others, the length of t is dictated by the
% underlying mesh, which we can force to be equal
if strcmp(p.Results.method,'hist')
   if ~isscalar(bw)
      error('''hist'' method requires same bandwidth applied to all columns.');
   end
elseif strcmp(p.Results.method,'qkde') || strcmp(p.Results.method,'kde')
   sizeBw = size(bw);
   if isscalar(bw)
      % Apply the same bandwidth to all elements of eventTimes
      bw = repmat(bw,nRows,nGrps);
   elseif isrow(bw) %isvector(bw)
      % If row vector, length must match nGrps
   elseif iscolumn(bw)
      % if column, must match nRows
   elseif (sizeBw(1)==nRows) && (size(Bw(1))==nCols)
      % if 2-d matrix, must match eventTimes
   else
      error('bad size bw');
   end
else
   % remaining methods ignore bw
   fprintf('bw parameter was passed in, but will be ignored for the requested method');
end

%if isempty(p.Results.bw) make bw optional, estimate for
% 1) sshist method
% 2) qkde || kde w/ gaussian kernel botev method
% 3?) qkde || kde w/ boxcar use sshist

%% Set up start and end time
[tStart,tEnd] = deal(min(window(:,1)),max(window(:,2)));

%% Time vector
dt = p.Results.dt;
if strcmp(p.Results.method,'qkde') || strcmp(p.Results.method,'kde')
   t = (tStart:dt:tEnd)';
   nBins = length(t);
elseif strcmp(p.Results.method,'hist')
   % Sets up bin edges to use HISTC
   nBins = ceil((tEnd-tStart)/bw) + 1;
   t = (tStart + (0:(nBins-1))*bw)';
elseif strcmp(p.Results.method,'bars')
   % need to tweak barsP to accept passed through inputs
   % as well as pass back outputs
   % Kass points out that BARS is intended for use in smoothing the PSTH 
   % after pooling across trials (http://goo.gl/AN4i3)
   % this means we should return reps
   % effectively, we skip the nRows loop.
else
   % new methods?
end

%% Estimate rate
reps = nan(nBins,nRows,nGrps);
grpCount = 1;
for i = grpInd % groups
   for j = 1:nRows % rows
      eventTemp = eventTimes{j,i}(:);
      if ~any(isnan(eventTemp)) % TODO is this too restrictive?
         eventTemp = eventTemp((eventTemp>=t(1)) & (eventTemp<=t(end)));
         if ~isempty(eventTemp)
            if strcmp(p.Results.method,'qkde')
               reps(:,j,grpCount) = qkde(t,eventTemp,bw(j,i),dt,p.Results.kernel)*(1/dt);
            elseif strcmp(p.Results.method,'kde')
               lambda = ksdensity(eventTemp,t,'kernel',p.Results.kernel,'width',bw(j,i));
               reps(:,j,grpCount) = numel(eventTemp)*lambda;
            else
               reps(:,j,grpCount) = histc(eventTemp,t)/bw;
            end
         else
            reps(:,j,grpCount) = 0;
         end
      end
   end
   grpCount = grpCount + 1;
end

%% Average & truncate to row-specific window if necessary
if nargout < 2
   r = windowPsth(t,reps,window);
else
   [r,r_sem,count,reps] = windowPsth(t,reps,window);
end

if strcmp(p.Results.method,'hist')
   if p.Results.centerHist
      t = t + bw/2;
   end
end
