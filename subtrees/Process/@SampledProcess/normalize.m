function self = normalize(self,event,varargin)

p = inputParser;
p.KeepUnmatched = true;
p.FunctionName = 'SpectralProcess normalize';
p.addRequired('event',@(x) isnumeric(x) || isa(x,'metadata.Event'));
p.addParameter('window',[],@(x) isnumeric(x) && (size(x,2)==2));
p.addParameter('eventStart',true,@(x) isscalar(x) && islogical(x));
p.addParameter('method','divide',@(x) any(strcmp(x,...
   {'s' 'subtract' 'z', 'z-score' 'd' 'divide' 's-avg' 'subtract-avg'...
   'z-avg', 'z-score-avg' 'z-avg', 'z-score-avg' 'd-avg' 'divide-avg'})));
p.parse(event,varargin{:});
par = p.Results;
meanPar = p.Unmatched;

if ~isempty(par.window)
   assert(all([self.dt] <= (par.window(2)-par.window(1))),...
      'SampledProcess:normalize:window:InputValue',...
      'Window must be wide enough to contain at least 1 sample');
end

obj = copy(self);
% Sync to event
par.processTime = false;
obj.sync__(par.event,par);

if strfind(par.method,'avg')
   meanPar.outputStruct = true;
   temp = obj.mean(meanPar);
   normMean = nanmean(temp.values);
   normStd = nanstd(temp.values);
   uLabels = temp.labels;
else
   normVals = arrayfun(@(x) x.values{1},obj,'uni',0);
end

for i = 1:numel(self)
   switch par.method
      case {'s' 'subtract'}
         self(i).values{1} = bsxfun(@minus,self(i).values{1},nanmean(normVals{i},1));
      case {'z', 'z-score'}
         self(i).values{1} = bsxfun(@minus,self(i).values{1},nanmean(normVals{i},1));
         self(i).values{1} = bsxfun(@rdivide,self(i).values{1},nanstd(normVals{i},0,1));
      case {'d' 'divide'}
         self(i).values{1} = bsxfun(@rdivide,self(i).values{1},nanmean(normVals{i},1)) - 1;
      case {'s-avg' 'subtract-avg'}
         [~,ind] = intersect(self(i).labels,uLabels,'stable');
         if any(ind)
            self(i).values{1} = bsxfun(@minus,self(i).values{1},normMean(1,:,ind));
         else
            self(i).values{1}(:,:) = NaN;
         end
      case {'z-avg', 'z-score-avg'}
         [~,ind] = intersect(self(i).labels,uLabels,'stable');
         if any(ind)
            self(i).values{1} = bsxfun(@minus,self(i).values{1},normMean(1,:,ind));
            self(i).values{1} = bsxfun(@rdivide,self(i).values{1},normStd(1,:,ind));
         else
            self(i).values{1}(:,:) = NaN;
         end
      case {'d-avg' 'divide-avg'}
         [~,ind] = intersect(self(i).labels,uLabels,'stable');
         if any(ind)
            self(i).values{1} = bsxfun(@rdivide,self(i).values{1},normMean(1,:,ind));
         else
            self(i).values{1}(:,:) = NaN;
         end
   end
end
