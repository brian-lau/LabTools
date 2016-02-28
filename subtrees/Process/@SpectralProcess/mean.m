% MEAN - Take mean of array of SpectralProcesses
%
%     [out,n,count] = mean(SpectralProcess,varargin)
%     [out,n,count] = SpectralProcess.mean(varargin)
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% INPUTS
%     method  - string, optional, default = 'nanmean'
%             One of {'mean' 'nanmean' 'trimmean' 'winsor'} defining the
%             type of mean desired
%     minN    - integer, optional, default = 1
%             minimum number of instances for each unique label required to
%             form a mean
%     outputStruct - bool, optional, default = False
%             True indicates results should be returned as a structure,
%             otherwise they are returned as a Process
%     percent - scalar in [0 100], optional, default = 5
%             When mean method is either 'trimmean' or 'winsor', indicates
%             the percentage of data (lower = percent and upper = [100 - percent]
%             removed from mean or clamped at value corresponding to percentile
%
%     Additional name/value pairs are passed to SUBSET.
%
% OUTPUTS
%     out    - structure or Process object containing mean
%     n      - # of Processes contributing to the mean of each channel
%     count  - # of non-NaN values contributing to the mean of each sample
%
% EXAMPLES
%     l(1) = metadata.Label('name','01D');
%     l(2) = metadata.Label('name','12D');
%     s(1) = SampledProcess(randn(1000,2),'Fs',1000,'labels',l);
%     s(2) = SampledProcess(randn(1000,2),'Fs',1000,'labels',l);
%     tf = tfr(s,'tStep',.25,'tBlock',.5);
%     m = tf.mean();
%     plot(m,'title',true);
% 
%     m = tf.mean('label',l(2));
%     plot(m,'title',true);
%
%     tf(1).quality(1) = 0;
%     [m,n] = tf.mean('func',@(x) x.quality>0)
%
% SEE ALSO
%     SUBSET

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process
function [out,n,count] = mean(self,varargin)

p = inputParser;
p.KeepUnmatched = true;
p.FunctionName = 'SpectralProcess mean method';
p.addParameter('outputStruct',false,@(x) isscalar(x) || islogical(x));
p.addParameter('minN',1,@(x) isscalar(x));
p.addParameter('method','nanmean',@(x) any(strcmp(x,...
   {'mean' 'nanmean' 'trimmean' 'winsor'})));
p.addParameter('percent',5,@(x) isscalar(x));
p.parse(varargin{:});
par = p.Results;
subsetPar = p.Unmatched;

try
   % TODO this will not work properly with multiple windows
   relWindow = cat(1,self.relWindow);
   if size(unique(relWindow,'rows'),1) ~= 1
      error('Not all processes have the same relative window.');
   else
      relWindow = relWindow(1,:);
   end
   % TODO possibly adjust windows to min/max across all processes?
catch err
   if strcmp(err.identifier,'MATLAB:catenate:dimensionMismatch')
      cause = MException('SpectralProcess:mean:InputValue',...
         'Not all processes have the same number of windows.');
      err = addCause(err,cause);
   end
   rethrow(err);
end

try
   f = cat(1,self.f);
   if size(unique(f,'rows'),1) ~= 1
      error('Not all processes have the same frequency sampling.');
   else
      f = f(1,:);
   end
catch err
   if strcmp(err.identifier,'MATLAB:catenate:dimensionMismatch')
      cause = MException('SpectralProcess:mean:InputValue',...
         'Not all processes have the same frequency sampling.');
      err = addCause(err,cause);
   end
   rethrow(err);
end

% previously, I exactly matched the time vectors, but I'm worried that this
% will fail due to small floating point inaccuracies that accumulate
% this also suggests that even with exact window/tStep/tBlock/offset, we
% could end up with a missing sample at the beginning end of window?
try
   dt = cat(1,self.dt);
   if size(unique(dt)) ~= 1
      error('Not all processes have the same frequency sampling.');
   else
      dt = dt(1,:);
   end
catch err
   if strcmp(err.identifier,'MATLAB:catenate:dimensionMismatch')
      cause = MException('SpectralProcess:mean:InputValue',...
         'Not all processes have the same temporal sampling.');
      err = addCause(err,cause);
   end
   rethrow(err);
end

try
   tBlock = cat(1,self.tBlock);
   if size(unique(tBlock)) ~= 1
      error('Not all processes have the same temporal sampling.');
   else
      tBlock = tBlock(1,:);
   end
catch err
   if strcmp(err.identifier,'MATLAB:catenate:dimensionMismatch')
      cause = MException('SpectralProcess:mean:InputValue',...
         'Not all processes have the same frequency sampling.');
      err = addCause(err,cause);
   end
   rethrow(err);
end

fn = fieldnames(subsetPar);
if isempty(fn)
   obj = self;
else
   obj = copy(self);
   obj.subset(subsetPar);
end
[s,l] = extract(obj);
s = cat(3,s.values);
l = cat(2,l{:});

uLabels = unique(cat(2,obj.labels),'stable');

values = nan(size(s,1),size(s,2),numel(uLabels));
if nargout == 3
   count = zeros(size(s,1),size(s,2),numel(uLabels));
end
n = zeros(size(uLabels));
for i = 1:numel(uLabels)
   ind = l == uLabels(i); % handle equality!
   if sum(ind) >= par.minN
      switch par.method
         case 'nanmean'
            values(:,:,i) = nanmean(s(:,:,ind),3);
         case 'mean'
            values(:,:,i) = mean(s(:,:,ind),3);
         case 'trimmean'
            values(:,:,i) = trimmean(s(:,:,ind),par.percent,'round',3);
      end
   end
   if nargout == 3
      count(:,:,i) = sum(~isnan(s(:,:,ind)),3);
   end
   n(i) = sum(ind);
end

% Only return valid means
ind = n >= par.minN;
n = n(ind);
if nargout == 3
   count = count(:,:,ind);
end

if par.outputStruct
   out.values = values(:,:,ind);
   out.labels = uLabels(ind);
else
   out = SpectralProcess(values(:,:,ind),...
      'f',f,...
      'tBlock',tBlock,...
      'tStep',dt,...
      'labels',uLabels(ind),...
      'tStart',relWindow(1),...
      'tEnd',relWindow(2)...
      );
end