% labels
% min
% excludeNaNs

% checktimes?
% quality check

function [out,n] = mean(self,varargin)

p = inputParser;
p.FunctionName = 'SpectralProcess mean method';
p.addParameter('labels',[],@(x) ischar(x) || iscell(x) || isa(x,'metadata.Label'));
p.addParameter('outputStruct',false,@(x) isscalar(x) || islogical(x));
p.addParameter('minN',1,@(x) isscalar(x));
p.parse(varargin{:});
par = p.Results;

% % WHAT DEFINES A COMPATIBLE MEAN???
% should match relwindow? or at least windowsize
%  should also match stepsize (same number of samples)
% should match frequencies
% 
% % how to specify output
% what is the tStart/End
% what is offset/window?

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
      cause = MException('SpectralProcess:mean:InputValue',...
         'Not all processes have the same number of windows.');
      err = addCause(err,cause);
   end
   rethrow(err);
end

try
   f = cat(1,self.f);
   if size(unique(f,'rows'),1) ~= 1
      error('Not all processes have the same frequency sampling.');
   else
      f = f(1,:);
   end
catch err
   if strcmp(err.identifier,'MATLAB:catenate:dimensionMismatch')
      cause = MException('SpectralProcess:mean:InputValue',...
         'Not all processes have the same frequency sampling.');
      err = addCause(err,cause);
   end
   rethrow(err);
end

% previously, I exactly matched the time vectors, but I'm worried that this
% will fail due to small floating point inaccuracies that accumulate
% this also suggests that even with exact window/tStep/tBlock/offset, we
% could end up with a missing sample at the beginning end of window?
try
   dt = cat(1,self.dt);
   if size(unique(dt)) ~= 1
      error('Not all processes have the same frequency sampling.');
   else
      dt = dt(1,:);
   end
catch err
   if strcmp(err.identifier,'MATLAB:catenate:dimensionMismatch')
      cause = MException('SpectralProcess:mean:InputValue',...
         'Not all processes have the same frequency sampling.');
      err = addCause(err,cause);
   end
   rethrow(err);
end

try
   tBlock = cat(1,self.tBlock);
   if size(unique(tBlock)) ~= 1
      error('Not all processes have the same frequency sampling.');
   else
      tBlock = tBlock(1,:);
   end
catch err
   if strcmp(err.identifier,'MATLAB:catenate:dimensionMismatch')
      cause = MException('SpectralProcess:mean:InputValue',...
         'Not all processes have the same frequency sampling.');
      err = addCause(err,cause);
   end
   rethrow(err);
end

uLabels = unique(cat(2,self.labels),'stable');
if ~isempty(par.labels)
   uLabels = intersect(par.labels,uLabels,'stable');
end

[s,l] = extract(self,uLabels);
s = cat(3,s.values);
l = cat(2,l{:});

values = nan(size(s,1),size(s,2),numel(uLabels));
n = zeros(size(uLabels));
for i = 1:numel(uLabels)
   ind = l == uLabels(i); % handle equality!
   if sum(ind) >= par.minN
      values(:,:,i) = nanmean(s(:,:,ind),3);
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
   out = SpectralProcess(values(:,:,ind),...
      'f',f,...
      'tBlock',tBlock,...
      'tStep',dt,...
      'labels',uLabels(ind),...
      'tStart',relWindow(1),...
      'tEnd',relWindow(2)...
      );
   %out.cumulOffset = self(1).cumulOffset;
end