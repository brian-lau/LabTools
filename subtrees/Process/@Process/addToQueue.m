% Add to function evaluation queue
% 

% {function_name args status}

%function addToQueue(self,nout,varargin)
function addToQueue(self,varargin)

% assert numel(stack)>=2?
stack = dbstack('-completenames');
f = stack(2).name; % maybe take from end of stack?

% Setter calls using set()format (hgsetget)
if strfind(f,'.set.')
   temp = regexp(f,'\.','split');
   varargin = [temp(3) varargin];
   f = 'set';
end

for i = 1:numel(self)
   n = size(self(i).queue,1) + 1;
   self(i).queue{n,1} = f;
   self(i).queue{n,2} = varargin;
   self(i).queue{n,3} = ~self(i).lazyEval;
   %self(i).queue{n,4} = nout;
end