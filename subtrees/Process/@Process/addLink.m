% add link
function addLink(self,varargin)

if ~self.running && ~self.lazy
   error('cannot ');
end
stack = dbstack('-completenames');

self.chain{end+1,1} = {stack(2).name , varargin , self.running};


% addLink(func,args,status)
% pull funcstr from dbstack? mfilename?
% self.chain{end+1,1} = {'map',{func}};
% 
% {num func args status}
