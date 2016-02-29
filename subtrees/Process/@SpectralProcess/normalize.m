% NORMALIZE - Normalize values of array of SampledProcesses
%
%     normalize(SampledProcess,event,varargin)
%     SampledProcess.normalize(event,varargin)
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% INPUTS
%     event   - numeric or metadata.Event, required
%             Can be an vector, in which case, the length must match the
%             number of elements in SampledProcess array
%     window  - 1x2 vector, optional, default = window including all data
%             Can be an nx2 matrix, in which case, the n must match the
%             number of elements in SampledProcess array
%     eventStart - boolean, optional, default = True
%             Indicates whether to use tStart or tEnd of metadata.Event
%     method  - string, optional, default = 'z-score'
%             Specifies normalization method, one of:
%             'subtract'  - subtract baseline mean
%             'z-score'   - subtract baseline mean, then divide by baseline
%                           standard deviation
%             'divide'    - divide by baseline mean
%             'percentage'- 100*(signal-baseline mean)/baseline mean
%             
%             For the options above baseline values are the values from
%             each element of SampledProcess, aligned on 'event' in 'window'.
%             Adding '-avg' to the method (ie, 'z-score-avg', 'divide-avg')
%             will concatenate baseline values from all elements of the
%             SampledProcess, and apply the method to the values of each
%             element using this concatenated baseline.
%
%     Additional name/value pairs are passed to MEAN.
%
%     EXAMPLES
%     % Signals with some time-frequency structure
%     y1 = chirp([0:0.001:2]',10,2,10,'q');
%     y2 = chirp([0:0.001:2]',10,2,60,'q');
%     s(1) = SampledProcess([y1;y1+y2],'Fs',1000,'offset',-2);
%     s(2) = SampledProcess([y1*.25;y1+y2],'Fs',1000,'offset',-2);
%
%     % Estimate time-frequency representation
%     tf = tfr(s,'method','stft','f',1:100,'tBlock',.5,'tStep',.05);
%     plot(tf,'log',false);
%     % Normalize
%     tf.normalize(0,'window',[-1.75 0],'method','subtract');
%     plot(tf,'log',false);

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process
function self = normalize(self,event,varargin)

p = inputParser;
p.KeepUnmatched = true;
p.FunctionName = 'SpectralProcess normalize';
p.addRequired('event',@(x) isnumeric(x) || isa(x,'metadata.Event'));
p.addParameter('window',[],@(x) isnumeric(x) && (size(x,2)==2));
p.addParameter('eventStart',true,@(x) isscalar(x) && islogical(x));
p.addParameter('method','z-score',@(x) any(strcmp(x,...
   {'s' 'subtract' 'z', 'z-score' 'd' 'divide' 'p' 'percentage' 's-avg' 'subtract-avg'...
   'z-avg', 'z-score-avg' 'z-avg', 'z-score-avg' 'd-avg' 'divide-avg' 'p-avg' 'percentage-avg'})));
p.parse(event,varargin{:});
par = p.Results;
meanPar = p.Unmatched;

if ~isempty(par.window)
   assert(all([self.dt] <= (par.window(2)-par.window(1))),...
      'SpectralProcess:normalize:window:InputValue',...
      'Window must be wide enough to contain at least 1 sample');
end

if strfind(par.method,'avg')
   try
      f = cat(1,self.f);
   catch err
      if strcmp(err.identifier,'MATLAB:catenate:dimensionMismatch')
         cause = MException('SpectralProcess:normalize:InputValue',...
            'Not all processes have the same frequency axis.');
         err = addCause(err,cause);
      end
      rethrow(err);
   end
   if size(unique(f,'rows'),1) ~= 1
      error('SpectralProcess:normalize:InputValue',...
         'Not all processes have common frequency axis.');
   else
      f = f(1,:);
      nf = numel(f);
   end
end

obj = copy(self);
% Sync to event
par.processTime = false;
obj.sync__(par.event,par);

if strfind(par.method,'avg')
   meanPar.outputStruct = true;
   temp = obj.mean(meanPar);
   uLabels = temp.labels;
   normMean = nanmean(temp.values); % OK, mean of means
   normStd = zeros(size(normMean));
   for i = 1:numel(uLabels)
      ind = temp.fullLabels == uLabels(i);
      v = temp.fullValues(:,:,ind);
      % Collapse over Processes, permuting to stack time as columns
      v = reshape(permute(v,[2 1 3]),nf,size(v,1)*sum(ind));
      normStd(1,:,i) = nanstd(v,[],2);
   end
else
   normVals = arrayfun(@(x) x.values{1},obj,'uni',0);
end
clear obj;

for i = 1:numel(self)
   switch par.method
      case {'s' 'subtract'}
         self(i).values{1} = bsxfun(@minus,self(i).values{1},nanmean(normVals{i},1));
      case {'z', 'z-score'}
         self(i).values{1} = bsxfun(@minus,self(i).values{1},nanmean(normVals{i},1));
         self(i).values{1} = bsxfun(@rdivide,self(i).values{1},nanstd(normVals{i},0,1));
      case {'d' 'divide'}
         self(i).values{1} = bsxfun(@rdivide,self(i).values{1},nanmean(normVals{i},1));
      case {'p' 'percentage'}
         self(i).values{1} = 100*(bsxfun(@rdivide,self(i).values{1},nanmean(normVals{i},1)) - 1);
      case {'s-avg' 'subtract-avg'}
         [~,ind] = intersect(self(i).labels,uLabels,'stable');
         if any(ind)
            self(i).values{1} = bsxfun(@minus,self(i).values{1},normMean(1,:,ind));
         else
            self(i).values{1}(:,:,:) = NaN;
         end
      case {'z-avg', 'z-score-avg'}
         [~,ind] = intersect(self(i).labels,uLabels,'stable');
         if any(ind)
            self(i).values{1} = bsxfun(@minus,self(i).values{1},normMean(1,:,ind));
            self(i).values{1} = bsxfun(@rdivide,self(i).values{1},normStd(1,:,ind));
         else
            self(i).values{1}(:,:,:) = NaN;
         end
      case {'d-avg' 'divide-avg'}
         [~,ind] = intersect(self(i).labels,uLabels,'stable');
         if any(ind)
            self(i).values{1} = bsxfun(@rdivide,self(i).values{1},normMean(1,:,ind));
         else
            self(i).values{1}(:,:,:) = NaN;
         end
      case {'p-avg' 'percentage-avg'}
         [~,ind] = intersect(self(i).labels,uLabels,'stable');
         if any(ind)
            self(i).values{1} = 100*(bsxfun(@rdivide,self(i).values{1},normMean(1,:,ind)) - 1);
         else
            self(i).values{1}(:,:,:) = NaN;
         end
   end
end
