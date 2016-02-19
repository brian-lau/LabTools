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
%p.addParameter('quality',[],@(x) isnumeric(x));
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

labels = obj.labels;
baseInd = obj.selection_(:);
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

%labelInd = [];
if ~isempty(par.label) % requires full label match (ignores labelProp/Val)
   if isa(par.label,'metadata.Label') 
      [~,ind] = intersect(obj.labels,par.label,'stable');
      labelInd = false(nl,1);
      labelInd(ind) = true;
   end
elseif ~isempty(par.labelVal)
   if isnumeric(par.labelVal)
      v = arrayfun(@(x) ismember(x.(par.labelProp),par.labelVal),labels,'uni',0,'ErrorHandler',@valErrorHandler);
   elseif ischar(par.labelVal)
      v = arrayfun(@(x) strcmp(x.(par.labelProp),par.labelVal),labels,'uni',0,'ErrorHandler',@valErrorHandler);
   else
      % works for handles
      v = arrayfun(@(x) x.(par.labelProp)==par.labelVal,obj.labels,'uni',0,'ErrorHandler',@valErrorHandler);
   end
   labelInd = vertcat(v{:});
%    % labels are heterogenous, so we filter out elements that do not possess
%    % the property of interest (treated as false)
%    matchProp = find(isprop(obj.labels,par.labelProp));
%    if any(matchProp)
%       
%       labels = obj.labels(matchProp);
%       
%       % labelProp values are unconstrained, so we filter out possibilities
%       % where they differ from labelVal in type
%       v = {labels.(par.labelProp)};
%       types = cellfun(@(x) class(x),v,'uni',0);
%       match = find(strcmp(types,class(par.labelVal)));
%       
%       if isnumeric(par.labelVal) % I think this will work with handles too
%          I = find(ismember([v{match}],par.labelVal));
%       elseif ischar(par.labelVal)
%          I = find(ismember(v(match),par.labelVal));
%       else
%          mc = metaclass(par.labelVal);
%          if any(ismember({mc.SuperclassList.Name},{'handle','matlab.mixin.Copyable'}))
%             I = find(ismember([v{match}],par.labelVal));
%          else
%             error('Process:subset:labelVal','Matching for class(labelVal) not implemented.');
%          end
%       end
%       
%       % Reinsert the matching indices for the reduced subset back into full index
%       labelInd = false(1,obj.n);
%       labelInd(matchProp(match(I))) = true;
%       labelInd = find(labelInd);
%    end
else
   labelInd = false(nl,1);
end

% qualityInd = [];
% if ~isempty(par.quality)
%    qualityInd = find(ismember(obj.quality,par.quality));
% end
if ~isempty(par.func)
   % TODO cell array of function handles, allow multiple arbitrary crit
   funcInd = arrayfun(par.func,events,'ErrorHandler',@funcErrorHandler);
else
   funcInd = false(nl,1);
end

switch lower(par.logic)
   case {'or' 'union'}
      %selection = unique(vertcat(indexInd(:),labelInd(:),qualityInd(:)));
      keyboard
      selection = indexInd | labelInd | funcInd;
   case {'and' 'intersection'}
      if isempty(par.index)
         indexInd = true(nl,1);
      end
      if isempty(par.labelVal)
         labelInd = true(nl,1);
      end
      if isempty(par.func)
         funcInd = true(nl,1);
      end
      selection = indexInd & labelInd & funcInd;
%       if ~isempty(par.index)
%          selection = indexInd;
%       else
%          selection = baseInd;
%       end
%       if ~isempty(par.label)
%          selection = intersect(selection,labelInd);
%       end
%       if ~isempty(par.quality)
%          selection = intersect(selection,qualityInd);
%       end
   case {'xor' 'setxor'}
      %selection = setxor(baseInd,unionm(indexInd,labelInd,qualityInd));
      selection = sum([indexInd,labelInd,funcInd],2) == 1;
   otherwise
      selection = false(nl,1);
end

% Match against current selection
tf = baseInd & selection;
% [~,selection] = intersect(baseInd,selection);
% tf = false(size(obj.selection_));
% tf(selection) = true;
obj.selection_ = tf';

obj.applySubset();

%%
function result = funcErrorHandler(err,varargin)
if strcmp(err.identifier,'MATLAB:noSuchMethodOrField');
   result = false;
else
   err = MException(err.identifier,err.message);
   cause = MException('EventProcess:find:func',...
      'Problem in function handle.');
   err = addCause(err,cause);
   throw(err);
end

function result = valErrorHandler(err,varargin)
if strcmp(err.identifier,'MATLAB:noSuchMethodOrField');
   result = false;
else
   err = MException(err.identifier,err.message);
   cause = MException('EventProcess:find:eventProp',...
      'Problem in eventProp/Val pair.');
   err = addCause(err,cause);
   throw(err);
end