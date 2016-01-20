% should be able to handle passing in raw values to normalize by

function self = normalize(self,event,varargin)

nObj = numel(self);
if nObj > 1
   for i = 1:nObj
      normalize(self(i),varargin{:});
   end
   return
end

p = inputParser;
p.KeepUnmatched= true;
p.FunctionName = 'SpectralProcess normalize';
p.addRequired('event',@(x) isnumeric(x) || isa(x,'metadata.Event'));
p.addOptional('window',[],@(x) isnumeric(x) && (size(x,1)==1) && (size(x,2)==2)); 
p.addOptional('eventStart',true,@(x) isscalar(x) && islogical(x)); 
p.addOptional('method','divide',@ischar); 
p.parse(event,varargin{:});

par = p.Results;

nObj = numel(self);
if (numel(event)==1) && (nObj>1)
   event = repmat(event,size(self));
end
assert(numel(event)==numel(self),'SampledProcess:sync:InputValue',...
   'numel(event) should match numel(SampledProcess)');

if all(isa(event,'metadata.Event'))
   if par.eventStart
      offset = [event.tStart]';
   else
      offset = [event.tEnd]';
   end
else
   offset = event(:);
end

if isempty(par.window) % FIXME: not working?
   % find window that includes all data
   temp = vertcat(self.window);
   temp = bsxfun(@minus,temp,offset);
   window = [min(temp(:,1)) max(temp(:,2))];
   window = self.checkWindow(window,size(window,1));
   clear temp;
else
   window = par.window;
end

origWindow = window;
% Window at original sample times
if (size(window,1)>1) || (numel(offset)>1)
   window = bsxfun(@plus,window,offset);
   window = bsxfun(@plus,window,-vec([self.cumulOffset]));
   window = num2cell(window,2);
else
   window = window + offset - self.cumulOffset;
end
self.setWindow(window);

% Extract window values, and reset process 
% error if window produces nothing (all nans? or window smaller than tBlock)
normVals = self.values{1};
undo(self);

switch lower(par.method)
   case {'subtract'}
      self.values{1} = bsxfun(@minus,self.values{1},nanmean(normVals));
   case {'z', 'z-score'}
      self.values{1} = bsxfun(@minus,self.values{1},nanmean(normVals));
      self.values{1} = bsxfun(@rdivide,self.values{1},nanstd(normVals));
   case {'divide'}
      self.values{1} = bsxfun(@rdivide,self.values{1},nanmean(normVals));
   otherwise
      error('Bad method');
end

