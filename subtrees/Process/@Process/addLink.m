% add link
% {func args status}

function addLink(self,varargin)

% assert numel(stack)>=2?
stack = dbstack('-completenames');

n = size(self.chain,1) + 1;
self.chain{n,1} = stack(2).name; % maybe take from end of stack? 
self.chain{n,2} = varargin;
self.chain{n,3} = ~self.lazyEval;
