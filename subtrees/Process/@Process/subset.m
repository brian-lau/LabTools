% SUBSET - Select subsets of Process signals
%
%     subset(Process,varargin);
%
%     When input is an array of Processes, will iterate and subset each.
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% INPUTS
%     index   - integer vector, optional
%               Indices picking out columns of current selection. This is
%               the only parameter that can be passed in without its name,
%               in which case, it must be the first input.
%     label   - string, cell array or array of metadata.Labels, optional
%               Matched against Process labels of current selection. If
%               used, labelProp/Val will be ignored.
%     labelProp - string, optional, default = 'name'
%               metadata.Label property to match against.
%     labelVal - arbitrary, optional
%               Value of corresponding labelProp to use in defining subset.
%               isequal or == must be a valid method.
%     quality - scalar, optional
%               Matched against current Process quality
%     func    - function handle, optional
%               Input is the Process object itself, and the function handle
%               should return a vector of booleans with size equal to the #
%               of channels in Process
%     logic   - string, optional, default = 'or'
%               One of following defining the logic to be applied:
%               {'any' 'or' 'union'} logical OR of all criteria
%               'notany' negation of logical OR of all criteria
%               {'all' 'and' 'intersection'} logical AND of all criteria
%               'notall' negation of logical AND of all criteria
%     nansequal - boolean, optional, default = True
%               True indicates that NaNs should be treated as equal
%     strictHandleEq - boolean, optional, default = False
%               True indicates that handle compatible labelVals will
%               require that the handles match, not just the contents of
%               the handle object
%     subsetOriginal - boolean, optional, default = False
%               True indicates that original times/values will also be
%               subset, which cannot be reversed by resetting
%
% EXAMPLES
%     p = PointProcess('times',{(1:2)' (6:10)' (11:20)'},'quality',[0 1 1]);
%     p.subset(2) % channel 2 by index
%
%     p.reset();
%     p.subset('labelVal','id2') % channel 2 by name
%
%     p.reset();
%     p.subset('quality',2) % channel 2,3 by quality
%
%     p.reset();
%     p.labels(1).grouping = 'group1';
%     p.labels(3).grouping = 'group1';
%     p.subset('labelProp','grouping','labelVal','group1') % channels 1,3 by grouping
%
%     p.reset();
%     p.subset('labelProp','grouping','labelVal','group1','logic','notany') % channels 2 by exclusion
%
%     p.reset();
%     p.subset('func',@(x) x.quality > 0.25) % channels 2,3 by function

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process

function self = subset(self,varargin)

if mod(nargin-1,2)==1 && ~isstruct(varargin{1})
   assert(isnumeric(varargin{1}),...
      'Process:subset:InputFormat',...
      'Single inputs must be passed in as array of integer values');
   varargin = [{'index'} varargin];
end

p = inputParser;
p.KeepUnmatched = false;
p.FunctionName = 'Process subset method';
p.addParameter('index',[],@(x) isnumeric(x));
p.addParameter('label',[],@(x) ischar(x) || iscell(x) || isa(x,'metadata.Label'));
p.addParameter('labelProp','name',@ischar);
p.addParameter('labelVal',[]);
p.addParameter('quality',[],@(x) isnumeric(x) || isa(x,'function_handle'));
p.addParameter('func',[],@(x) isa(x,'function_handle'));
p.addParameter('logic','or',@(x) any(strcmp(x,...
   {'any' 'or' 'union' 'notany' 'all' 'and' 'intersection' 'notall'})));
p.addParameter('nansequal',true,@islogical);
p.addParameter('strictHandleEq',false,@islogical);
p.addParameter('subsetOriginal',false,@islogical);
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

[~,labelInd] = labels.match(par);

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
   case {'or' 'union' 'any'}
      selection = indexInd | labelInd | qualityInd | funcInd;
   case {'notany'}
      selection = ~(indexInd | labelInd | qualityInd | funcInd);
   case {'and' 'intersection' 'all' 'notall'}
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
      if strcmp(par.logic,'notall')
         selection = ~selection;
      end
end

% Match against current selection
tf = baseInd & selection;
obj.selection_ = tf';

if ~all(obj.selection_)
   obj.applySubset(par.subsetOriginal);
end
