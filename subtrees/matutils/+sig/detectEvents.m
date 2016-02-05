% detectEvents               Detect events in analog trace
% 
%     [events,t] = detectEvents(x,dt,thresh,maxDuration,minDuration,plotFlag)
%
%     Utility to detect logic pulses from analog data. Events are defined
%     by a step from low->high followed by a step from high->low.
%
%     INPUTS
%     x           - vector of data to detect events in
%
%     OPTIONAL
%     dt          - sampling time (1/Fs)
%     thresh      - threshold for detecting events
%     maxDuration - maximum event duration
%     minDuration - minimum event duration
%     plotFlag    - set true to plot x along with detected events
%
%     OUTPUTS
%     events      - Nx2 array with the [onset offset] times of each event
%     t           - time vector for x

%     $ Copyright (C) 2012 Brian Lau http://www.subcortex.net/research/code $
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
%     brian 09.07.12 written

% TODO
% interpolation
% filtering

function [events,t] = detectEvents(x,dt,thresh,maxDuration,minDuration,plotFlag)

if nargin < 6
   plotFlag = false;
end
if nargin < 5
   minDuration = .05; % Seconds
end
if nargin < 4
   maxDuration = 1000; % Seconds
end
if nargin < 3
   % Guess a threshold
   thresh = ((max(x)-min(x))/2) + min(x);
end
if nargin < 2
   dt = 1;
   minDuration = 5; % Samples
   maxDuration = 1000; % Samples
end

ind = x(:) > thresh;
dind = diff(ind); % +1 event goes hi, -1 event goes lo
posind = find(dind==1);
negind = find(dind==-1);

if (length(posind)==0) || (length(negind)==0)
   events = [NaN NaN];
   t = NaN;
   fprintf('No events found');
   return;
end

if negind(1) < posind(1)
   %% events started hi, assume time 1 is onset
   %posind = [0 ; posind];
   temp = posind;
   posind = negind;
   negind = temp;
end
if (length(posind)>length(negind)) && (posind(end)>negind(end))
   % events end hi, assume last point is offset
   negind = [negind ; length(x)];
end

if length(posind) ~= length(negind)
   error('Event mismatch');
end

events = [posind, negind]*dt;
dur = events(:,2) - events(:,1);
ind = (dur > maxDuration) | (dur < minDuration);
events(ind,:) = [];

if nargout == 2
   t = dt*(0:size(x,1)-1);
end

if (nargout==0) || plotFlag
   t = dt*(0:size(x,1)-1);
   figure; hold on
   plot(t,x);
   plot(t,x,'b.');
   plot(events(:,1),thresh,'kx')
   plot(events(:,2),thresh,'ro')
end