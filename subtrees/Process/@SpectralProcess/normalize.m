% should be able to handle passing in raw values to normalize by
% need to implement normalize by average across elements
% qualityMask
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
method = lower(par.method);

% Allow same event or different events
% Allow same window or different windows

if ~isempty(par.window)
   assert(all([self.tStep] <= (par.window(2)-par.window(1))),...
      'SpectralProcess:normalize:window:InputValue',...
      'Window must be wide enough to contain at least 1 sample');
end

uLabels = unique(cat(2,self.labels),'stable');
nLabels = numel(uLabels);

if strfind(method,'avg')
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

history = num2cell([self.history]);
[self.history] = deal(true);

% Sync to event
par.processTime = false;
self.sync__(par.event,par);

if strfind(method,'avg')
   [s,l] = extract(self);
   s = cat(3,s.values);
   l = cat(2,l{:});
   normMean = nan(1,size(s,2),nLabels);
   normStd = nan(1,size(s,2),nLabels);
   for i = 1:nLabels
      ind = l==uLabels(i);
      if any(ind)
         % Collapse over Processes, permuting to stack time windows
         temp = reshape(permute(s(:,:,ind),[2 1 3]),nf,size(s,1)*sum(ind))';
         normMean(1,:,i) = nanmean(temp);
         normStd(1,:,i) = nanstd(temp);
      end
   end
else
   normVals = arrayfun(@(x) x.values{1},self,'uni',0);
end
% reset process
self.undo(2);
[self.history] = deal(history{:});

for i = 1:numel(self)
   switch method
      case {'s' 'subtract'}
         self(i).values{1} = bsxfun(@minus,self(i).values{1},nanmean(normVals{i},1));
      case {'z', 'z-score'}
         self(i).values{1} = bsxfun(@minus,self(i).values{1},nanmean(normVals{i},1));
         self(i).values{1} = bsxfun(@rdivide,self(i).values{1},nanstd(normVals{i},0,1));
      case {'d' 'divide'}
         self(i).values{1} = bsxfun(@rdivide,self(i).values{1},nanmean(normVals{i},1)) - 1;
      case {'s-avg' 'subtract-avg'}
         [~,ind] = intersect(self(i).labels,uLabels,'stable');
         self(i).values{1} = bsxfun(@minus,self(i).values{1},normMean(1,:,ind));
      case {'z-avg', 'z-score-avg'}
         [~,ind] = intersect(self(i).labels,uLabels,'stable');
         self(i).values{1} = bsxfun(@minus,self(i).values{1},normMean(1,:,ind));
         self(i).values{1} = bsxfun(@rdivide,self(i).values{1},normStd(1,:,ind));
      case {'d-avg' 'divide-avg'}
         [~,ind] = intersect(self(i).labels,uLabels,'stable');
         self(i).values{1} = bsxfun(@rdivide,self(i).values{1},normMean(1,:,ind));
   end
end
