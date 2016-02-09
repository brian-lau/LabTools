function self = subset(self,varargin)

p = inputParser;
p.KeepUnmatched= false;
p.FunctionName = 'Process subset method';
p.addParameter('index',[],@(x) isnumeric(x));
p.addParameter('labels',[],@(x) iscell(x) || isa(x,'metadata.Label'));
p.addParameter('quality',[],@(x) isnumeric(x));
p.parse(varargin{:});

self.selection_(1:10) = false;
%keyboard
self.values{1} = self.values{1}(:,self.selection_);
self.labels = self.labels(self.selection_);
self.quality = self.quality(self.selection_);
