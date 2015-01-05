function [values,times] = sync(self,event,varargin)

p = inputParser;
p.KeepUnmatched= false;
p.FunctionName = 'PointProcess sync';
p.addRequired('event',@(x) isnumeric(x));
p.addParamValue('window',[]);
p.parse(event,varargin{:});

self.setInclusiveWindow;

if isempty(p.Results.window)
   temp = vertcat(self.window);
   temp = bsxfun(@minus,temp,event(:));
   window = [min(temp(:,1)) max(temp(:,2))];
else
   window = self.checkWindow(p.Results.window,size(p.Results.window,1));
end

nObj = numel(self);
if size(window,1) == 1
   window = repmat(window,nObj,1);
   window = bsxfun(@plus,window,event(:));
   
   self.setWindow(window);
   self.setOffset(-event);
else
   error('not done')
end

if nargout
   % TODO for pointprocess not obvious...
   [times,values] = arrayfun(@(x) deal(x.times{1,:},x.values{1,:}),self,'uni',false);
end
