% MEAN - Take element-wise mean values in array of SampledProcesses
%
%     [out,n,count] = mean(SampledProcess,varargin)
%     [out,n,count] = SampledProcess.mean(varargin)
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
%     s(1) = SampledProcess([ones(100,1), 2*ones(100,1)],'Fs',1000,'labels',l);
%     s(2) = SampledProcess([ones(100,1), 2*ones(100,1)],'Fs',1000,'labels',l);
%     m = s.mean();
%     plot(m)
% 
%     m = s.mean('label',l(2));
%     plot(m);
%
%     s(1).quality(1) = 0;
%     [m,n] = s.mean('func',@(x) x.quality>0)
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
p.FunctionName = 'SampledProcess mean method';
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
      cause = MException('SampledProcess:mean:InputValue',...
         'Not all processes have the same number of windows.');
      err = addCause(err,cause);
   end
   rethrow(err);
end

try
   dt = cat(1,self.dt);
   if size(unique(dt)) ~= 1
      error('Not all processes have the same temporal sampling.');
   else
      dt = dt(1,:);
   end
catch err
   if strcmp(err.identifier,'MATLAB:catenate:dimensionMismatch')
      cause = MException('SampledProcess:mean:InputValue',...
         'Not all processes have the same temporal sampling.');
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
s = cat(2,s.values);
l = cat(2,l{:});

uLabels = unique(cat(2,obj.labels),'stable');
clear obj;

values = nan(size(s,1),numel(uLabels));
if nargout == 3
   count = zeros(size(s,1),numel(uLabels));
end
ind = false(numel(uLabels),size(s,2));
n = zeros(size(uLabels));
for i = 1:numel(uLabels)
   ind(i,:) = l == uLabels(i); % handle equality!
   if sum(ind(i,:)) >= par.minN
      switch par.method
         case 'nanmean'
            values(:,i) = nanmean(s(:,ind(i,:)),2);
         case 'mean'
            values(:,i) = mean(s(:,ind(i,:)),2);
         case 'trimmean'
            values(:,i) = trimmean(s(:,ind(i,:)),par.percent,'round',2);
         case 'winsor'
            % TODO, update stat.winsor to work columnwise
            values(:,i) = nanmean(stat.winsor(s(:,ind(i,:)),...
               [par.percent 100-par.percent]),2);
      end
   end
   if nargout == 3
      count(:,i) = sum(~isnan(s(:,ind(i,:))),2);
   end
   n(i) = sum(ind(i,:));
end

% Only return valid means
ind2 = n >= par.minN;
n = n(ind2);
if nargout == 3
   count = count(:,ind2);
end

if par.outputStruct
   out.values = values(:,ind2);
   out.labels = uLabels(ind2);
   out.fullValues = s;
   out.fullLabels = l;
   out.fullIndex = ind;
else
   out = SampledProcess(values(:,ind2),...
      'Fs',1/dt,...
      'labels',uLabels(ind2),...
      'tStart',relWindow(1),...
      'tEnd',relWindow(2)...
      );
end