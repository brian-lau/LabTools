function self = subset(self,varargin)

p = inputParser;
p.KeepUnmatched= false;
p.FunctionName = 'Process subset method';
p.addParameter('index',[],@(x) isnumeric(x));
p.addParameter('label',[],@(x) ischar(x) || iscell(x) || isa(x,'metadata.Label'));
p.addParameter('labelProp','name',@ischar);
p.addParameter('labelVal',[]);
p.addParameter('quality',[],@(x) isnumeric(x));
p.addParameter('logic','or',@(x) any(strcmp(x,{'or' 'union' 'and' 'intersection' 'xor' 'setxor'})));
p.parse(varargin{:});
par = p.Results;

baseInd = find(self.selection_);

indexInd = [];
if ~isempty(par.index)
   indexInd = par.index;
   assert(all(mod(indexInd,1)==0),'Process:subset:InputFormat','Index must be integers');
   ind = (indexInd<=0)|(indexInd>self.n);
   if any(ind)
      warning('Process:subset','Out of range indices ignored.');
      indexInd(ind) = [];
   end
end

labelInd = [];
if ~isempty(par.label) % requires full label match (ignores labelProp/Val)
   if isa(par.label,'metadata.Label') 
      [~,labelInd] = intersect(self.labels,par.label);
   end
elseif ~isempty(par.labelVal)
   % labels are heterogenous, so we filter out elements that do not possess
   % the property of interest (treated as false)
   matchProp = find(isprop(self.labels,par.labelProp));
   labels = self.labels(matchProp);
   
   % labelProp values are unconstrained, so we filter out possibilities
   % where they differ from labelVal in type
   v = {labels.(par.labelProp)};
   types = cellfun(@(x) class(x),v,'uni',0);
   match = find(strcmp(types,class(par.labelVal)));
   
   if isnumeric(par.labelVal) % I think this will work with handles too
      I = find(ismember([v{match}],par.labelVal));
   elseif ischar(par.labelVal)
      I = find(ismember(v(match),par.labelVal));
   else
      mc = metaclass(par.labelVal);
      if any(ismember({mc.SuperclassList.Name},{'handle','matlab.mixin.Copyable'}))
         I = find(ismember([v{match}],par.labelVal));
      else
         error('Process:subset:labelVal','Matching for class(labelVal) not implemented.');
      end
   end
   
   % Reinsert the matching indices for the reduced subset back into full index
   labelInd = false(1,self.n);
   labelInd(matchProp(match(I))) = true;
   labelInd = find(labelInd);
end

qualityInd = [];
if ~isempty(par.quality)
   qualityInd = find(ismember(self.quality,par.quality));
end

switch lower(par.logic)
   case {'or' 'union'}
      selection = unionm(indexInd,labelInd,qualityInd);
   case {'and' 'intersection'}
      if ~isempty(par.index)
         selection = indexInd;
      else
         selection = baseInd;
      end
      if ~isempty(par.label)
         selection = intersect(selection,labelInd);
      end
      if ~isempty(par.quality)
         selection = intersect(selection,qualityInd);
      end
   case {'xor' 'setxor'}
      selection = setxor(baseInd,unionm(indexInd,labelInd,qualityInd));
end

% Match against current selection
[~,selection] = intersect(baseInd,selection);
tf = false(size(self.selection_));
tf(selection) = true;
self.selection_ = tf;

self.applySubset();