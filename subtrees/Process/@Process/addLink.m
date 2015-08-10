% add link
% {func args status}

function addLink(self,varargin)

% assert 
if ~self.evalImmediately && ~self.lazy
   error('cannot ');
end
% assert numel(stack)>2?
stack = dbstack('-completenames');

% maybe take from end of stack? 
self.chain{end+1,1} = {stack(2).name , varargin , self.running};

