% should be able to handle passing in raw values to normalize by
% need to implement normalize by average across elements
% qualityMask
function self = normalize(self,event,varargin)

p = inputParser;
p.KeepUnmatched= true;
p.FunctionName = 'SpectralProcess normalize';
p.addRequired('event',@(x) isnumeric(x) || isa(x,'metadata.Event'));
p.addParameter('window',[],@(x) isnumeric(x) && (size(x,1)==1) && (size(x,2)==2));
p.addParameter('eventStart',true,@(x) isscalar(x) && islogical(x));
p.addParameter('method','divide',@(x) any(strcmp(x,...
   {'s' 'subtract' 'z', 'z-score' 'd' 'divide' 's-avg' 'subtract-avg'...
   'z-avg', 'z-score-avg' 'z-avg', 'z-score-avg' 'd-avg' 'divide-avg'})));
p.parse(event,varargin{:});
par = p.Results;
method = lower(par.method);

if ~isempty(par.window)
   assert(all([self.tStep] <= (par.window(2)-par.window(1))),...
      'SpectralProcess:normalize:window:InputValue',...
      'Window must be wide enough to contain at least 1 sample');
end

if strfind(method,'avg')
   % Methods deriving normalization from all elements of the process must
   % have the same number of channels & same frequency resolution
   try
      n = size(unique(cat(1,self.labels)),1);
   catch err
      if strcmp(err.identifier,'MATLAB:catenate:dimensionMismatch')
         cause = MException('SpectralProcess:normalize:InputValue',...
            'Not all processes have the same number of labels');
         err = addCause(err,cause);
      end
      rethrow(err);
   end
   if n ~= 1
      error('SpectralProcess:normalize:InputValue',...
         'Not all processes have common labels.');
   end
   if length(unique(arrayfun(@(x) numel(x.f),self))) ~= 1
      error('SpectralProcess:normalize:InputValue',...
         'Not all processes have common frequency axis.');
   end
end

history = num2cell([self.history]);
[self.history] = deal(true);

par.processTime = false;
self.sync__(par.event,par);

% Extract window values, and reset process
% error if window produces nothing (all nans? or window smaller than tBlock)
normVals = arrayfun(@(x) x.values{1},self,'uni',0);
self.undo(2);
[self.history] = deal(history{:});

if strfind(method,'avg')
   normMean = nanmean(cat(1,normVals{:}));
   if strncmp(method,'d',1)
      normStd = nanstd(cat(1,normVals{:}));
   end
end

for i = 1:numel(self)
   switch method
      case {'s' 'subtract'}
         self(i).values{1} = bsxfun(@minus,self(i).values{1},nanmean(normVals{i}));
      case {'z', 'z-score'}
         self(i).values{1} = bsxfun(@minus,self(i).values{1},nanmean(normVals{i}));
         self(i).values{1} = bsxfun(@rdivide,self(i).values{1},nanstd(normVals{i}));
      case {'d' 'divide'}
         self(i).values{1} = bsxfun(@rdivide,self(i).values{1},nanmean(normVals{i}));
      case {'s-avg' 'subtract-avg'}
         self(i).values{1} = bsxfun(@minus,self(i).values{1},normMean);
      case {'z-avg', 'z-score-avg'}
         self(i).values{1} = bsxfun(@minus,self(i).values{1},normMean);
         self(i).values{1} = bsxfun(@rdivide,self(i).values{1},normStd);
      case {'d-avg' 'divide-avg'}
         self(i).values{1} = bsxfun(@rdivide,self(i).values{1},normMean);
   end
end
