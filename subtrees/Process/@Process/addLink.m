% add link
% {func args status}

function addLink(self,varargin)

if ~self.running && ~self.lazy
   error('cannot ');
end
stack = dbstack('-completenames');

self.chain{end+1,1} = {stack(2).name , varargin , self.running};

