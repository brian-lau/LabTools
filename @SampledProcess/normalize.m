% NORMALIZE - Normalize values of array of SpectralProcesses
%
%     normalize(SpectralProcess,event,varargin)
%     SpectralProcess.normalize(event,varargin)
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% INPUTS
%     event   - numeric or metadata.Event, required
%             Can be an vector, in which case, the length must match the
%             number of elements in SpectralProcess array
%     window  - 1x2 vector, optional, default = window including all data
%             Can be an nx2 matrix, in which case, the n must match the
%             number of elements in SpectralProcess array
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
%             each element of SpectralProcess, aligned on 'event' in 'window'.
%             Adding '-avg' to the method (ie, 'z-score-avg', 'divide-avg')
%             will concatenate baseline values from all elements of the
%             SpectralProcess, and apply the method to the values of each
%             element using this concatenated baseline.
%
%     Additional name/value pairs are passed to MEAN.
%
% EXAMPLES
%     % Array of SampledProcesses, each with 3 channels (identical labels)
%     s = SampledProcess('values',[1 + randn(1000,1),2 + 2*randn(1000,1),3 + 3*randn(1000,1)],'Fs',1000);
%     s(2) = SampledProcess('values',10*[1 + randn(1000,1),2 + 2*randn(1000,1),3 + 3*randn(1000,1)],...
%            'Fs',1000,'labels',s(1).labels);
%     plot(s)
%
%     % Normalize
%     s.normalize(0,'window',[0 0.5],'method','z-score');
%     plot(s)

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
p.addParameter('process',[],@(x) isa(x,'SampledProcess'));
p.parse(event,varargin{:});
par = p.Results;
meanPar = p.Unmatched;

if ~isempty(par.process)
   % DEFINING A COMPATIBLE 2ND PROCESS
   % dt not necessary since we collapse over time
   % if isavg, all labels in self must exist in obj
   % if ~isavg, all labels and label order must match identically
   obj = copy(par.process);
else
   obj = copy(self);
end

if ~isempty(par.window)
   assert(all([obj.dt] <= (par.window(2)-par.window(1))),...
      'SampledProcess:normalize:window:InputValue',...
      'Window must be wide enough to contain at least 1 sample');
end

% Sync to event
par.processTime = false;
obj.sync__(par.event,par);

isavg = ~isempty(strfind(par.method,'avg'));
if ~isavg
   if numel(obj) ~= numel(self)
      fprintf('%s normalization converted to %s-avg method due to array mismatch.\n',...
         upper(par.method),upper(par.method));
      par.method = [par.method '-avg'];
      isavg = true;
   end
end

if isavg
   meanPar.outputStruct = true;
   temp = obj.mean(meanPar);
   uLabels = temp.labels;
   normMean = nanmean(temp.values); % OK, mean of means
   if strfind(par.method,'z')
      normStd = zeros(size(normMean));
      for i = 1:numel(uLabels)
         ind = temp.fullLabels == uLabels(i);
         v = temp.fullValues(:,ind);
         normStd(i) = nanstd(v(:));
      end
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
            self(i).values{1} = bsxfun(@minus,self(i).values{1},normMean(ind));
         else
            self(i).values{1}(:,:) = NaN;
         end
      case {'z-avg', 'z-score-avg'}
         [~,ind] = intersect(self(i).labels,uLabels,'stable');
         if any(ind)
            self(i).values{1} = bsxfun(@minus,self(i).values{1},normMean(ind));
            self(i).values{1} = bsxfun(@rdivide,self(i).values{1},normStd(ind));
         else
            self(i).values{1}(:,:) = NaN;
         end
      case {'d-avg' 'divide-avg'}
         [~,ind] = intersect(self(i).labels,uLabels,'stable');
         if any(ind)
            self(i).values{1} = bsxfun(@rdivide,self(i).values{1},normMean(ind));
         else
            self(i).values{1}(:,:) = NaN;
         end
      case {'p-avg' 'percentage-avg'}
         [~,ind] = intersect(self(i).labels,uLabels,'stable');
         if any(ind)
            self(i).values{1} = 100*(bsxfun(@rdivide,self(i).values{1},normMean(ind)) - 1);
         else
            self(i).values{1}(:,:) = NaN;
         end
   end
end
