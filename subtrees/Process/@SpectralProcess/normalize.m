% should be able to handle passing in raw values to normalize by
% need to implement normalize by average across elements
function self = normalize(self,event,varargin)

p = inputParser;
p.KeepUnmatched= true;
p.FunctionName = 'SpectralProcess normalize';
p.addRequired('event',@(x) isnumeric(x) || isa(x,'metadata.Event'));
p.addParameter('window',[],@(x) isnumeric(x) && (size(x,1)==1) && (size(x,2)==2));
p.addParameter('eventStart',true,@(x) isscalar(x) && islogical(x));
p.addParameter('method','divide',@ischar);
p.parse(event,varargin{:});
par = p.Results;

% validate that window contains at least one sample

history = num2cell([self.history]);
[self.history] = deal(true);

par.processTime = false;
self.sync__(par.event,par);

% Extract window values, and reset process
% error if window produces nothing (all nans? or window smaller than tBlock)
normVals = arrayfun(@(x) x.values{1},self,'uni',0);
self.undo(2);
[self.history] = deal(history{:});

for i = 1:numel(self)
   switch lower(par.method)
      case {'subtract'}
         self(i).values{1} = bsxfun(@minus,self(i).values{1},nanmean(normVals{i}));
      case {'z', 'z-score'}
         self(i).values{1} = bsxfun(@minus,self(i).values{1},nanmean(normVals{i}));
         self(i).values{1} = bsxfun(@rdivide,self(i).values{1},nanstd(normVals{i}));
      case {'divide'}
         self(i).values{1} = bsxfun(@rdivide,self(i).values{1},nanmean(normVals{i}));
      otherwise
         error('Bad method');
   end
end
