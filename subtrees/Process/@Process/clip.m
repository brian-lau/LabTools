% CLIP - Clip Process values
%
%     clip(Process,value,varargin)
%     Process.clip(value,varargin)
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% INPUTS
%     value - numeric scalar, required
%             Value to clip at
%     method  - string, optional, default = 'positive'
%             Specifies clipping method, one of:
%             'positive'  - set values >= value to value
%             {'negative' 'invert'}  - set values <= value to value
%             'abs'    - set abs(values) >= abs(value) to value
%     setval - numeric scalar, optional, default = value
%             Replace values meeting clip criteria with setval
%
%     EXAMPLES
%     s = SampledProcess([-10:10]');
%     s.values{1}
%     s.clip(6); 
%     s.clip(-7,'method','invert','setval',NaN);
%     s.values{1}

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process
function self = clip(self,value,varargin)

p = inputParser;
p.KeepUnmatched = false;
p.FunctionName = 'Process clip method';
p.addRequired('value',@(x) isnumeric(x) && isscalar(x));
p.addParameter('method','positive',@(x) any(strcmp(x,...
   {'invert' 'negative' 'abs'})));
p.addParameter('setval',[],@(x) isnumeric(x) && isscalar(x) && ~isnan(x));
p.parse(value,varargin{:});
par = p.Results;

if isempty(par.setval)
   setval = par.value;
else
   setval = par.setval;
end

switch par.method
   case {'positive'}
      f = @(x) x.*(x<par.value) + setval.*(x>=par.value);
   case {'invert' 'negative'}
      f = @(x) x.*(x>par.value) + setval.*(x<=par.value);
   case {'abs'}
      f = @(x) x.*(abs(x)<abs(par.value)) + setval.*(abs(x)>=abs(par.value));
end

self.map(@(x) f(x));