% windowPsth                 Window PSTH estimates
% 
%     [r,r_sem,count,reps] = windowPsth(t,reps,window)
%
%     Create a PSTH given single-trial PSTHs. The average is conditional on 
%     each trial having made it within the window. Otherwise, the each PSTH
%     is NaN-padded.
%
%     INPUTS
%     t      - [nBins x 1] time vector
%     reps   - [nBins x nRows x nGrps] matrix of signals to be windowed
%     window - [1 x 2] vector of start and end time, or
%              [nRows x 2] matrix of trial-specific windows
%
%     OUTPUTS
%     r      - [nBins x nGrps] mean rate
%     r_sem  - [nBins x nGrps] standard error of mean rate
%     count  - [nBins x 1] vector of # of valid trials per time point
%     reps   - [nBins x nRows x nGrps] rate estimates for individual trials
%              NaNs replace all elements outside of window
%

%     $ Copyright (C) 2010-2012 Brian Lau http://www.subcortex.net/ $
%
%     REVISION HISTORY:
%     brian 06.27.10 written
%     brian 11.11.12 refactor, remove r_std output

% TODO
% windowPsth -> windowSignal
% perhaps this needs to interface cleanly with timeseries object?

function [r,r_sem,count,reps] = windowPsth(t,reps,window)

[nBins,nRows,nGrps] = size(reps);

if size(window,1) == 1
   window = repmat(window,nRows,1);
end

count = zeros(nBins,nGrps);
r = zeros(nBins,nGrps);
if nargout >= 2
   r_sem = zeros(nBins,nGrps);
end

for i = 1:nGrps
   for j = 1:nRows
      ind = (t<window(j,1)) | (t>window(j,2));
      reps(ind,j,i) = NaN;
   end
end

for i = 1:nGrps
   r(:,i) = nanmean(reps(:,:,i),2);
   if exist('r_sem','var')
      bool = ~isnan(reps(:,:,i));
      count(:,i) = sum(squeeze(bool),2);
      r_sem(:,i) = nanstd(reps(:,:,i),0,2) ./ sqrt(count(:,i));
   end
end
