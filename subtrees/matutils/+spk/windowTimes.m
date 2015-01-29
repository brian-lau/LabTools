% windowTimes                Get event times (possibly offset) within window
% 
%     [winTimes,adjWindow,offsetEvents,count] = windowTimes(eventTimes,varargin)
%
%     Window then offset (default)
% 
%     events            |     |  |     |  |  |     |
%     time        0  1  2  3  4  5  6  7  8  9  10 11
%                       ^___________^
%                       window = [2 6] 
% 
%     events            |     |  |     
%     time        0  1  2  3  4  5  6  7  8  9  10 11
%                       )----> offset = 2
% 
%     events                  |     |  |     
%     time        0  1  2  3  4  5  6  7  8  9  10 11
% 
%     Offset then window (set 'windowThenOffset' to false)
% 
%     events            |     |  |     |  |  |     |
%     time        0  1  2  3  4  5  6  7  8  9  10 11
%                       )----> offset = 2
%    
%     events                  |     |  |     |  |  |  |
%     time        0  1  2  3  4  5  6  7  8  9  10 11 13
%                       ^___________^
%                       window = [2 6]
% 
%     events                  |     |
%     time        0  1  2  3  4  5  6  7  8  9  10 11 13
%                
%     Which format you use will depend on whether your window is is relative 
%     to different time from the eventTimes. For example, say you know you 
%     want a window = [0 4] after aligned to an event that occurs at time 2. 
%     You could pass in an offset = -2 and the window, but set the 
%     windowThenOffset parameter to false, which would return event times as
% 
%     events            |     |  |     |  |  |     |
%     time        0  1  2  3  4  5  6  7  8  9  10 11
%                 <-----( offset = -2
% 
%     events      |     |  |     |  |  |     |
%     time        0  1  2  3  4  5  6  7  8  9  10 11
%                 ^___________^
%                 window = [0 4]
% 
%     events      |     |  |
%     time        0  1  2  3  4  5  6  7  8  9  10 11
% 
%     You could achieve the same thing by passing in a different window that 
%     incorporates the offset implicitly, window = [0 4] + offset, but if you
%     want the event times returned relative to this window, you must also 
%     pass in the negative offset
% 
%     events            |     |  |     |  |  |     |
%     time        0  1  2  3  4  5  6  7  8  9  10 11
%                       ^___________^
%                       window = [2 6]
%
%     events            |     |  |
%     time        0  1  2  3  4  5  6  7  8  9  10 11
%                 <-----( offset = -2
%
%     events      |     |  |
%     time        0  1  2  3  4  5  6  7  8  9  10 11
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
%     NOTE that windowTimes requires one input in addition to eventTimes. 
%                   This can be 'offset' or 'window'.
%
%     OPTIONAL
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
%     events      - [nRows x arbitrary] matrix of numbers that are "aligned"
%                   along with eventTimes (ie. the same offset is applied).
%
%     OUTPUTS
%     winTimes     - Windowed event times
%     adjWindow    - Windows applied to event times. If windowThenOffset is
%                    true (default), same offset as applied to event times
%                    is applied to the windows.
%                    Two possible output formats,
%                     [1 x 2] : [start end] eventTimes was a row vector
%                     [nRows x 2] : eventTimes had nRows
%     offsetEvents -
%     count        - [nRows x nCols] # of event times within window
%
%     SEE ALSO
%     getPsth, plotRaster, checkWindow, checkOffset

%     $ Copyright (C) 2012 Brian Lau http://www.subcortex.net/ $
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
%     brian 11.15.12 refactored get_spkstats

% TODO
% x What happens to Nans?? Will now skip if any nans, restrictive
% x what should the default window be relative to?
% make sure that a nan element that is passed in eventTimes stays a nan on
% output
% should we allow for multiple windows? currently the accepted inputs are:
% 1) single window. applied to each row of eventTimes
%    this can be combined with independent sync for each row of eventTimes
%    Both window and sync apply to all columns of eventTimes
% 2) window and/or sync can have the same # of rows as eventTimes, in which
%    case, each row has it's own window/sync applied
% 
% how to allow for any number of windows applied to each row of eventTimes?
% 3) if window is cell array, apply each element of window to each element
%    of eventTimes. 
% But how to apply independent sets of windows to different elements of
% eventTimes?
% If window is a row cell array, then apply all windows to all eventTimes
% If window is a column cell array, and matches nRows, apply each row to
% each row of eventTimes? Should these be stored as matrices (2xN) or
% cells?
% 
% If any of the above are applied to window, they should also be applied to
% sync
% Fix to handle empty inputs, currently filled with NaNs?
% Also fix to handle NaN inputs, currently returned as empty!!!

function [winTimes,adjWindow,offsetEvents,count] = windowTimes(eventTimes,varargin)

import spk.*

[nRows,nCols] = size(eventTimes);

%% Parse inputs
p = inputParser;
p.KeepUnmatched= true; % prevents error if irrelevant parameters passed in
p.FunctionName = 'windowTimes';
p.addRequired('eventTimes',@(x) validateattributes(eventTimes,{'cell'},{'2d'}) );
p.addParamValue('offset',0,@(x) isnumeric(x) && (isscalar(x) || iscolumn(x)) );
p.addParamValue('colIndex',1:nCols,@(x) isnumeric(x) && all(x>0) && (max(x)<=nCols) );
p.addParamValue('window',[],@(x) validateattributes(eventTimes,{'numeric' 'cell'},{'2d'}) );
p.addParamValue('windowThenOffset',true,@islogical);
p.addParamValue('events',[],@(x) isnumeric(x) && (size(x,1)==nRows) );
p.addParamValue('rowIndex',true(nRows,nCols),@(x) islogical(x) && (size(x,1)==nRows) );
p.parse(eventTimes,varargin{:});

if nargin == 1
   error([p.FunctionName ':InputCount'],'You must pass in ''offset'' or ''window''');
end

%% Determine grouping
% grps = eventTimes when the number of eventTimes matches the number of trial indices
% When nCols = 1, grps = number of trial indices
nRowInds = size(p.Results.rowIndex,2);
if (nCols==1) && (nRowInds>1)
   grpInd = repmat(p.Results.colIndex,1,nRowInds);
   eventTimes = repmat(eventTimes,1,nRowInds);
   grpInd = 1:nRowInds;
else
   grpInd = p.Results.colIndex(:)';
end
nGrps = length(grpInd);

%% Set up window
if iscell(p.Results.window)
   % Currently works for one set of eventTimes, ie evenTimes = {[1xn]}
   if numel(eventTimes) == 1
      window = checkWindow(p.Results.window,nRows);
   else
      error([p.FunctionName ':InputFormat'],...
         'Can''t multiply window more than one set of eventTimes');
   end
else
   if isempty(p.Results.window)
      % NEED TO TEST, HACK looks like cases where there are no events
      temp = cell.minmax(eventTimes(:,p.Results.colIndex));
      if isempty(temp) %&& isempty(eventTimes)
         winTimes = {[]};
         adjWindow = [];
         offsetEvents = {[]};
         count = [];
         return
      end
      window = checkWindow(temp,nRows);
   else
      window = checkWindow(p.Results.window,nRows);
   end
end

%% Set up offset
offset = checkOffset(p.Results.offset,nRows);

%% Window and offset
% NaN-filled cell array. Necessary for cases where rowIndex excludes
% unequal numbers of trials per group, in which case, the output eventTimes
% will have NaN elements.
if iscell(window)
   % Handle special case of multiply windowing one set of eventTimes
   % Currently works for one set of eventTimes, ie evenTimes = {[1xn]}
   nWindow = length(window{1});
   winTimes = repmat({NaN},nWindow,1);
else
   % Normal case of one window per set of eventTimes
   winTimes = repmat({NaN},nRows,nGrps);
   nWindow = 1;
end
grpCount = 1;
for i = grpInd % groups
   rowIndex = find(p.Results.rowIndex(:,i));
   for j = rowIndex' % trials
      if iscell(window)
         % Handle special case of multiply windowing one set of eventTimes
         for k = 1:nWindow
            tStart = window{1}(k,1);
            tEnd = window{1}(k,2);
            if p.Results.windowThenOffset
               eventTemp = eventTimes{j,i};
               shift = offset;
            else
               eventTemp = eventTimes{j,i} + offset(j);
               shift = zeros(size(offset));
            end
            
            if ~isempty(eventTemp)
               ind = (eventTemp >= tStart) & (eventTemp <= tEnd);
               if ~isempty(ind)
                  % Rows index windows for the same set of eventTimes
                  winTimes{k,grpCount} = eventTemp(ind) + shift(j);
               end
            end
         end
      else
         tStart = window(j,1);
         tEnd = window(j,2);
         if p.Results.windowThenOffset
            eventTemp = eventTimes{j,i};
            shift = offset;
         else
            eventTemp = eventTimes{j,i} + offset(j);
            shift = zeros(size(offset));
         end
         
         if ~isempty(eventTemp)
            ind = (eventTemp >= tStart) & (eventTemp <= tEnd);
            if ~isempty(ind)
               % Rows index windows for each individual set of eventTimes
               winTimes{j,grpCount} = eventTemp(ind) + shift(j);
            end
         end         
      end
   end
   grpCount = grpCount + 1;
end

if nargout > 1
   if isempty(p.Results.window)
      temp = cell.minmax(winTimes);
      adjWindow = repmat(temp,nRows,1);
   else
      if p.Results.windowThenOffset
         % Adjust windows so windows correspond to winTimes
         adjWindow = window + repmat(offset,1,2);
      else
         % Windowed after offset, don't change
         adjWindow = window;
      end
   end
end

if nargout > 2
   if ~isempty(p.Results.events)
      offsetEvents = p.Results.events + repmat(offset,1,size(p.Results.events,2));
   else
      offsetEvents = [];
   end
end

if nargout > 3
   if isempty(winTimes)
      count = 0;
   else
      count = zeros(nRows,nCols);
      for i = 1:nRows
         for j = 1:nCols
            count(i,j) = numel(winTimes{i,j});
         end
      end
   end
end
