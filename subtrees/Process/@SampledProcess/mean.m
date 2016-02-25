% labels
% min
% excludeNaNs

% checktimes?
% quality check

function [out,n] = mean(self,varargin)

p = inputParser;
p.FunctionName = 'SampledProcess mean method';
p.addParameter('labels',[],@(x) ischar(x) || iscell(x) || isa(x,'metadata.Label'));
p.addParameter('outputStruct',false,@(x) isscalar(x) || islogical(x));
p.addParameter('minN',1,@(x) isscalar(x));
p.addParameter('type','nanmean',@ischar);
p.parse(varargin{:});
par = p.Results;

% issue warning when nObj = 1, tell them to use apply

try
   % TODO this will not work properly with multiple windows
   relWindow = cat(1,self.relWindow);
   if size(unique(relWindow,'rows'),1) ~= 1
      error('Not all processes have the same relative window.');
   else
      relWindow = relWindow(1,:);
   end
   % TODO possibly adjust windows to min/max across all processes?
catch err
   if strcmp(err.identifier,'MATLAB:catenate:dimensionMismatch')
      cause = MException('SampledProcess:mean:InputValue',...
         'Not all processes have the same number of windows.');
      err = addCause(err,cause);
   end
   rethrow(err);
end

try
   dt = cat(1,self.dt);
   if size(unique(dt)) ~= 1
      error('Not all processes have the same temporal sampling.');
   else
      dt = dt(1,:);
   end
catch err
   if strcmp(err.identifier,'MATLAB:catenate:dimensionMismatch')
      cause = MException('SampledProcess:mean:InputValue',...
         'Not all processes have the same temporal sampling.');
      err = addCause(err,cause);
   end
   rethrow(err);
end

uLabels = unique(cat(2,self.labels),'stable');
if ~isempty(par.labels)
   uLabels = intersect(par.labels,uLabels,'stable');
end

[s,l] = extract(self,uLabels);
s = cat(2,s.values);
l = cat(2,l{:});

values = nan(size(s,1),numel(uLabels));
n = zeros(size(uLabels));
for i = 1:numel(uLabels)
   ind = l == uLabels(i); % handle equality!
   if sum(ind) >= par.minN
      values(:,i) = nanmean(s(:,ind),2);
   end
   n(i) = sum(ind);
end

% Only return valid means
ind = n >= par.minN;
n = n(ind);

if par.outputStruct
   out.values = values(:,:,ind);
   out.labels = uLabels(ind);
else
   out = SampledProcess(values(:,ind),...
      'Fs',1/dt,...
      'labels',uLabels(ind),...
      'tStart',relWindow(1),...
      'tEnd',relWindow(2)...
      );
end