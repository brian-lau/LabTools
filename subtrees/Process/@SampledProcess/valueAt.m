function value = valueAt(self,time,varargin)

p = inputParser;
p.KeepUnmatched = true;
p.FunctionName = 'SampledProcess ';
p.addRequired('time',@(x) isnumeric(x));
p.addParameter('method','exact',@(x) any(strcmp(x,...
   {'exact' 'linear' 'nearest' 'next' 'previous' 'spline' 'cubic'})));
p.parse(time,varargin{:});
par = p.Results;
subsetPar = p.Unmatched;

fn = fieldnames(subsetPar);
if isempty(fn)
   obj = self;
else
   obj = copy(self);
   obj.subset(subsetPar);
end

nObj = numel(obj);

if nObj == 1
   value = valueAtEach(obj,par);
else
   value = cell(nObj,1);
   for i = 1:numel(obj)
      value{i} = valueAtEach(obj(i),par);
   end
end

function v = valueAtEach(obj,par)

switch par.method
   case 'exact'
      ind = ismember(obj.times{1},par.time);
      v = obj.values{1}(ind,:);
   case {'linear' 'nearest' 'next' 'previous' 'spline' 'cubic'}
      v = interp1(obj.times{1},obj.values{1},par.time(:),par.method);
end
