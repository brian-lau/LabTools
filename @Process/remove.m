% REMOVE - Remove channels from Process
%
%     remove(Process,varargin)
%     Process.remove(varargin)
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% INPUTS
%     logic - string, optional, default = 'all'
%           'all' removes channels matching all criteria
%           'any' removes channels matching any criteria
%
%     Available criteria are those that can be used in SUBSET.
%     All additional name/value pairs are passed to SUBSET.
%
% EXAMPLES
%     s = SampledProcess(randn(10));
%     s.remove('label',s.labels([3 4]))
%
%     s = SampledProcess(randn(10));
%     s.quality(1:2:end) = 0;
%     s.remove('label',s.labels(1:3),'quality',0)
%
% SEE ALSO
%     SUBSET

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process
function self = remove(self,varargin)

p = inputParser;
p.KeepUnmatched = true;
p.FunctionName = 'Process remove method';
p.addParameter('logic','all',...
   @(x) any(strcmp(x,{'any' 'or' 'union' 'all' 'and' 'intersection'})));
p.parse(varargin{:});
par = p.Results;
subsetPar = p.Unmatched;

fn = fieldnames(subsetPar);
if ~isempty(fn)
   switch par.logic
      case {'any' 'or' 'union'}
         subsetPar.logic = 'notany';
      case {'all' 'and' 'intersection'}
         subsetPar.logic = 'notall';
   end
   subsetPar.subsetOriginal = true;
   self.subset(subsetPar);
end