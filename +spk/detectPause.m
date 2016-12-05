% detectPause                Detect pauses in spike trains
% 
%     pauses = detectPause(spk,baseline,coreISI,maxAddedISI,minISI,maxMergeSpk)
%
%     Detect significant reductions in firing rate using a "Poisson surprise" method
%     to detect periods of significantly reduced activity. This implements a heuristic 
%     algorithm characterized in Elias et al., J Neurosci 2007 for detecting pauses 
%     in basal ganglia neurons.
%
%     The steps are:
%     1) define candidate pauses as interspike intervals (ISIs) < coreISI
%     2) add ISIs (up to maxAddedISI before & after ISIs defined in step 1)
%        until Poisson surprise decreases
%     3) Remove ISIs defined in step 2 that are less than minISI
%     4) Merge ISIs with fewer than maxMergeSpk
%
%     INPUTS
%     spk         - Array or cell array of spike times (in seconds)
%
%     OPTIONAL
%     baseline    - Baseline firing rate (spks/s). Defaults to estimating
%                   for each trial
%     coreISI     - Initial "core" ISI to find pauses
%     maxAddedISI - maximum # of ISIs to add (forward & backward) to pause
%     minISI      - minimum size of ISI after adding ISIs
%     maxMergeSpk - maximum # of spikes between pauses for merging (excluding those defining the pauses)
%
%     OUTPUTS
%     pauses      - struct array with fields:
%                   .r      - baseline rate (as probability/ms of spiking)
%                   .times0 - initial pass
%                   .times1 - after surprise
%                   .times2 - after threshold
%                   .times  - after merging (final output)
%
%     REFERENCE
%     Elias, S et al. (2007) Statistical properties of pauses of the high
%       frequency discharge neurons in the external segment of the globus pallidus.
%       J Neurosci 27(10): 2525-2538
%

%     $ Copyright (C) 2011-2012 Brian Lau http://www.subcortex.net/ $
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
%     brian 08.25.11 written
%     brian 12.25.11 fixed bug where t0 was not added for rare cases

function pauses = detectPause(spk,baseline,coreISI,maxAddedISI,minISI,maxMergeSpk)

import spk.*

if nargin < 6
   maxMergeSpk = 1; % maximum # of spikes between pauses for merging (excluding those defining the pauses)
end
if nargin < 5
   minISI = .300;   % minimum size of ISI after adding ISIs
end
if nargin < 4
   maxAddedISI = 5; % maximum # of ISIs to add (forward & backward) to pause
end
if nargin < 3
   coreISI = .25;   % Initial "core" ISI to find pauses
end
if nargin < 2
   estimate_baseline = true;
   baseline = [];
end
if isempty(baseline)
   estimate_baseline = true;
else
   estimate_baseline = false;
end

if iscell(spk)
   % Treat each row as a trial, for each cell (column)
   nTrials = size(spk,1);
   nCells = size(spk,2);
   for i = 1:nTrials
      for j = 1:nCells
         pauses(i,j) = detectPause(spk{i,j},baseline,coreISI,maxAddedISI,minISI,maxMergeSpk);
      end
   end
   return
end

if isempty(spk)
   pauses = return_struct([],[],[],[],[]);
   return
end
t0 = spk(1);
spk = spk - t0;

if estimate_baseline
   % Making convervative assumption, replace if total time is actually known
   totalT = spk(end) - spk(1);
   r = length(spk)/(totalT*1000);
else
   r = baseline/1000;
end

% Initial pass 
isi = diff(spk);
events = find(isi>=coreISI);
if isempty(events)
   pauses = return_struct(r,[],[],[],[]);
   return
end
pause0 = zeros(length(events),2);
for i = 1:length(events)
   pause0(i,:) = [spk(events(i)) spk(events(i)+1)];
end

% Grow the pause until surprise decreases
S = zeros(length(events),1+maxAddedISI);
for i = 1:length(events)
   T = 0;
   n = 0;
   % Add ISIs two at a time, one forward, one backward
   for j = 0:maxAddedISI
      n = n + 2*j;
      indForward = min(length(spk),events(i)+j+1);
      indBackward = max(1,events(i)-j);
      tempPause = [spk(indBackward) spk(indForward)];
      T = tempPause(2) - tempPause(1);
      p = poisspdf(n,r*T*1000); % Spktimes in seconds
      S(i,j+1) = -log(p); % Surprise
   end

   % Check whether surprise increases
   dS = diff(S(i,:),1,2);
   count = 1;
   nAddedISI(i) = maxAddedISI;
   while (count < size(S,2))
      if dS(count) < 0 
         nAddedISI(i) = count - 1;
         break;
      else 
         count = count + 1;
      end
   end
   
   indForward = min(length(spk),events(i)+nAddedISI(i)+1);
   indBackward = max(1,events(i)-nAddedISI(i));
   pause1(i,:) = [spk(indBackward) spk(indForward)];
end

if isempty(pause1)
   pauses = return_struct(r,pause0+t0,[],[],[]);
   return
end

% Threshold again for minimum length
pauseDur = pause1(:,2) - pause1(:,1);
ind = pauseDur >= minISI;
pause2 = pause1;
pause2(~ind,:) = [];

if isempty(pause2)
   pauses = return_struct(r,pause0+t0,pause1+t0,[],[]);
   return
end

% Merge pauses
count = 1;
pause3 = [];
p1 = pause2(1,:);
merge = false;
for i = 1:size(pause2,1)-1
   p2 = pause2(i+1,:);

   ind = (spk>p1(2)) & (spk<p2(1));
   if sum(ind) <= maxMergeSpk
      p1 = [p1(1) p2(2)];
      merge = true;
   else
      pause3(count,:) = p1;
      count = count + 1;
      p1 = p2;
      merge = false;
   end
   
   if i == size(pause2,1)-1
      if merge
         pause3 = [pause3 ; p1];
      else
         pause3 = [pause3 ; pause2(end,:)];
      end
   end
end

if size(pause2,1) == 1
   pause3 = pause2;
end

% Setup outputs
pauses = return_struct(r,pause0+t0,pause1+t0,pause2+t0,pause3+t0);

function pauses = return_struct(r,p0,p1,p2,p3);

pauses.r = r;
pauses.times0 = p0;
pauses.times1 = p1;
pauses.times2 = p2;
pauses.times  = p3;
