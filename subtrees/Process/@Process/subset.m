% Select subsets of Process signals based on three possible criteria
% index
% label
% quality

function self = subset(self,varargin)

if mod(nargin-1,2)==1 && ~isstruct(varargin{1})
   assert(isnumeric(varargin{1}),...
      'Process:subset:InputFormat',...
      'Single inputs must be passed in as array of numeric values');
   varargin = [{'index'} varargin];
end

p = inputParser;
p.KeepUnmatched= false;
p.FunctionName = 'Process subset method';
p.addParameter('index',[],@(x) isnumeric(x));
p.addParameter('label',[],@(x) ischar(x) || iscell(x) || isa(x,'metadata.Label'));
p.addParameter('labelProp','name',@ischar);
p.addParameter('labelVal',[]);
p.addParameter('quality',[],@(x) isnumeric(x) || isa(x,'function_handle'));
p.addParameter('func',[],@(x) isa(x,'function_handle'));
p.addParameter('logic','or',@(x) any(strcmp(x,{'or' 'union' 'and' 'intersection' 'xor' 'setxor'})));
p.parse(varargin{:});
par = p.Results;

nObj = numel(self);
for i = 1:nObj
   subsetEach(self(i),par);
end

%%
function subsetEach(obj,par)

labels = obj.labels';
baseInd = obj.selection_';
nl = numel(baseInd);

if ~isempty(par.index)
   assert(all(mod(par.index,1)==0),'Process:subset:InputFormat','Index must be integers');
   ind = (par.index<=0)|(par.index>obj.n);
   if any(ind)
      par.index(ind) = [];
      warning('Process:subset','Out of range indices ignored.');
   end
   ind = find(baseInd);
   indexInd = false(nl,1);
   indexInd(ind(par.index)) = true;
else
   indexInd = false(nl,1);
end

if ~isempty(par.label) % requires full label match (ignores labelProp/Val)
   if isa(par.label,'metadata.Label') 
      [~,ind] = intersect(obj.labels,par.label,'stable');
      labelInd = false(nl,1);
      labelInd(ind) = true;
   end
elseif ~isempty(par.labelVal)
   if ischar(par.labelVal)
      v = arrayfun(@(x) strcmp(x.(par.labelProp),par.labelVal),labels,'uni',0,'ErrorHandler',@valErrorHandler);
   else
      v = arrayfun(@(x) isequal(x.(par.labelProp),par.labelVal),labels,'uni',0,'ErrorHandler',@valErrorHandler);
   end
   labelInd = vertcat(v{:});
else
   labelInd = false(nl,1);
end

if ~isempty(par.quality)
   if isnumeric(par.quality)
      qualityInd = (obj.quality == par.quality)';
   else
      qualityInd = feval(par.quality,obj.quality');
   end
else
   qualityInd = false(nl,1);
end

if ~isempty(par.func)
   funcInd = feval(par.func,obj);
   funcInd = funcInd(:);
else
   funcInd = false(nl,1);
end

switch lower(par.logic)
   case {'or' 'union'}
      selection = indexInd | labelInd | qualityInd | funcInd;
   case {'and' 'intersection'}
      if isempty(par.index)
         indexInd = true(nl,1);
      end
      if isempty(par.labelVal) && isempty(par.label)
         labelInd = true(nl,1);
      end
      if isempty(par.quality)
         qualityInd = true(nl,1);
      end
      if isempty(par.func)
         funcInd = true(nl,1);
      end
      selection = indexInd & labelInd & qualityInd & funcInd;
   case {'xor' 'setxor'}
      selection = sum([indexInd,labelInd,qualityInd,funcInd],2) == 1;
   otherwise
      selection = false(nl,1);
end

% Match against current selection
tf = baseInd & selection;
obj.selection_ = tf';

obj.applySubset();

%%
function result = funcErrorHandler(err,varargin)
if strcmp(err.identifier,'MATLAB:noSuchMethodOrField');
   result = false;
else
   err = MException(err.identifier,err.message);
   cause = MException('Process:subset:func',...
      'Problem in function handle.');
   err = addCause(err,cause);
   throw(err);
end

function result = valErrorHandler(err,varargin)
if strcmp(err.identifier,'MATLAB:noSuchMethodOrField');
   result = false;
else
   err = MException(err.identifier,err.message);
   cause = MException('Process:subset:eventProp',...
      'Problem in eventProp/Val pair.');
   err = addCause(err,cause);
   throw(err);
end