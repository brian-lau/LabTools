function self = sync(self,event,varargin)

p = inputParser;
p.KeepUnmatched= true;
p.FunctionName = 'PointProcess sync';
p.addRequired('event',@(x) isnumeric(x) || isa(x,'metadata.Event'));
p.addOptional('window',[],@(x) isnumeric(x) && (size(x,1)==1) && (size(x,2)==2)); 
p.addOptional('eventStart',true,@(x) isscalar(x) && islogical(x)); 
p.parse(event,varargin{:});

nObj = numel(self);
if (numel(event)==1) && (nObj>1)
   event = repmat(event,size(self));
end
assert(numel(event)==numel(self),'PointProcess:sync:InputValue',...
   'numel(event) should match numel(PointProcess)');

if isa(event,'metadata.Event')
   if p.Results.eventStart
      offset = [event.tStart]';
   else
      offset = [event.tEnd]';
   end
else
   offset = event(:);
end

if isempty(p.Results.window)
   % find window that includes all data
   temp = vertcat(self.window);
   temp = bsxfun(@minus,temp,offset);
   window = [min(temp(:,1)) max(temp(:,2))];
   window = self.checkWindow(window,size(window,1));
   clear temp;
else
   window = p.Results.window;
end

% if (size(window,1)>1) && (nObj>1)
%    window = repmat(window,nObj,1);
% end
% 
% Window at original sample times
if (size(window,1)>1) || (numel(offset)>1)
   window = bsxfun(@plus,window,offset);
   window = num2cell(window,2);
else
   window = window + offset;
end

self.setWindow(window);
self.setOffset(-offset);
