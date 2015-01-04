% Apply a function to windowValues

% need to deal with arbitrary arguments to fun
% need to deal with arbitrary outputs from fun
% numel(self) > 1, see windowFun

function output = valueFun(self,fun,varargin)

% trap parameters
% Specific to cellfun 'UniformOutput' & ErrorHandler
% Non-specific
% args
% recurse
p = inputParser;
p.KeepUnmatched= true;
p.FunctionName = 'PointProcess valueFun method';
% Intercept some parameters to override defaults
p.addParamValue('nOutput',1,@islogical);
p.addParamValue('args',{},@iscell);
p.parse(varargin{:});
% Passed through to cellfun
params = p.Unmatched;

nWindow = size(self.window,1);
nArgs = numel(p.Results.args);
%          if nArgs ~= nargin(fun)
%             error('');
%          end

for i = 1:nWindow
   % Construct function arguments (see cellfun) as a cell array to
   % use comman-separated expansion
   temp = p.Results.args;
   args = cell(1,nArgs);
   for j = 1:numel(temp)
      args{j} = repmat(temp(j),1,self.count(i));
   end
   output{i,1} = cellfun(fun,self.values{i},args{:});
end
