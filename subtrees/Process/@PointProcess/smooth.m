function sp = smooth(self,varargin)

import spk.*

p = inputParser;
p.KeepUnmatched = true;
p.FunctionName = 'PointProcess smooth method';
p.parse(varargin{:});
% Passed through to getPsth
params = p.Unmatched;

n = numel(self);

tic;
%sp(1:n,1) = SampledProcess();
for i = 1:n
   r = getPsth(self(i).times,0.025,'method','qkde','window',self(i).relWindow,'dt',0.001);
   sp(i) = SampledProcess(r,'labels',self(i).labels,'tStart',self(i).relWindow(1),'Fs',1/0.001);
end
toc