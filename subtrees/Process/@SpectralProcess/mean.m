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

% WHAT DEFINES A COMPATIBLE MEAN???
f = cat(1,self.f);
if size(unique(f,'rows'),1) ~= 1
   error('shit');
else
   f = f(1,:);
end

uLabels = unique(cat(2,self.labels),'stable');
if ~isempty(par.labels)
   uLabels = intersect(par.labels,uLabels,'stable');
end

[s,l] = extract(self,uLabels);

times = cat(2,s.times);
if size(unique(times','rows'),1) ~= 1
   error('shit2');
else
   times = times(:,1);
end

tStep = cat(1,self.tStep);
if numel(unique(tStep)) ~= 1
   error('shit3');
else
   tStep = tStep(1);
end

s = cat(3,s.values);
l = cat(2,l{:});

values = zeros(size(s,1),size(s,2),numel(uLabels));
n = zeros(size(uLabels));
for i = 1:numel(uLabels)
   ind = l==uLabels(i);
   if sum(ind) >= par.minN
      values(:,:,i) = nanmean(s(:,:,ind),3);
   end
   n(i) = sum(ind);
end

ind = n >= par.minN;
n = n(ind);
if par.outputStruct
   out.values = values(:,:,ind);
   out.labels = uLabels(ind);
else
   out = SpectralProcess(values(:,:,ind),...
      'f',f,...
      'params',self(1).params,...
      'tBlock',self(1).tBlock,...
      'tStep',tStep,...
      'labels',uLabels(ind),...
      'tStart',self(1).relWindow(1),...
      'tEnd',self(1).relWindow(2)
      );
   out.cumulOffset = self(1).cumulOffset;
end