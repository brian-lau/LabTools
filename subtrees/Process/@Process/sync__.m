% x should allow resampling, no manage using resample(), interpolation as
% well
% x should handle different Fs for object array
% allow rounding to some arbitrary resolution
% multiple events? 
% multiple windows?
function self = sync__(self,event,varargin)

p = inputParser;
p.KeepUnmatched = true;
p.FunctionName = 'Process sync__';
p.addRequired('event',@(x) isnumeric(x) || isa(x,'metadata.Event'));
p.addParameter('window',[],@(x) isnumeric(x) && (size(x,1)==1) && (size(x,2)==2)); 
p.addParameter('eventStart',true,@(x) isscalar(x) && islogical(x)); 
p.addParameter('processTime',true,@(x) islogical(x));
p.parse(event,varargin{:});
par = p.Results;

%disp('running secret sync');

nObj = numel(self);
if (numel(event)==1) && (nObj>1)
   event = repmat(event,size(self));
end
assert(numel(event)==numel(self),'Process:sync:InputValue',...
   'numel(event) should match numel(Process)');

if all(isa(event,'metadata.Event'))
   if par.eventStart
      desiredOffset = [event.tStart]';
   else
      desiredOffset = [event.tEnd]';
   end
else
   desiredOffset = event(:);
end

if par.processTime
   % Round to the nearest sample in the process
   actualOffset = roundToProcessResolution(self,desiredOffset);
else
   % Otherwise sync to exact event time
   actualOffset = desiredOffset;
end

% Window relative to tStart
if isempty(par.window)
   % find window that includes all data
   temp = vertcat(self.window);
   temp = bsxfun(@minus,temp,actualOffset);
   window = [min(temp(:,1)) max(temp(:,2))];
   window = checkWindow(window,size(window,1));
   
   window = bsxfun(@plus,window,actualOffset);
   window = bsxfun(@plus,window,-vec([self.cumulOffset]));
   window = num2cell(window,2);
   clear temp;
else
   window = par.window;
end
window = bsxfun(@plus,window,actualOffset);
window = bsxfun(@plus,window,-vec([self.cumulOffset]));
window = num2cell(window,2);

self.setWindow(window);
self.setOffset(-actualOffset);
