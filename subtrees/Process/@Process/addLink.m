% add link
% {func args status}

function addLink(self,varargin)

% assert numel(stack)>=2?
stack = dbstack('-completenames');
f = stack(2).name; % maybe take from end of stack?

% Setter calls using set()format
if strfind(f,'.set.')
   temp = regexp(f,'\.','split');
   varargin = [temp(3) varargin];
   f = 'set';
end

n = size(self.chain,1) + 1;
self.chain{n,1} = f;
self.chain{n,2} = varargin;
self.chain{n,3} = ~self.lazyEval;
