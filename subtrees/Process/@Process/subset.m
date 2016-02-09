function self = subset(self,varargin)

p = inputParser;
p.KeepUnmatched= false;
p.FunctionName = 'Process subset method';
p.addParameter('index',[],@(x) isnumeric(x));
p.addParameter('labels',[],@(x) iscell(x) || isa(x,'metadata.Label'));
p.addParameter('quality',[],@(x) isnumeric(x));
p.parse(varargin{:});
par = p.Results;

baseInd = find(self.selection_);

indexInd = [];
if ~isempty(par.index)
   temp = par.index;
   assert(all(mod(temp,1)==0),'integers required');
   indexInd = temp((temp>0)&(temp<=self.n));
end

labelInd = [];
if ~isempty(par.labels)
   [~,labelInd] = intersect(self.labels,par.labels);
end

qualityInd = [];
if ~isempty(par.quality)
   qualityInd = find(ismember(self.quality,par.quality))
end

selection = [indexInd(:);labelInd(:);qualityInd(:)]
[~,selection] = intersect(baseInd,selection);
tf = false(size(self.selection_));
tf(selection) = true;
self.selection_ = tf;

self.applySubset();