% VALUEAT - Take value at particular time
%
%     value = valueAt(Process,time,varargin)
%     value = Process.valueAt(time,varargin)
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% INPUTS
%     time   - numeric vector, required
%             Specifying times at which values are requested
%     method - string, optional, default = 'exact'
%             'exact' - exact match to time
%             {'linear' 'nearest' 'next' 'previous' 'spline' 'cubic'}
%             interpolate according to method using interp1
%
%     Additional name/value pairs are passed to SUBSET.
%
% OUTPUTS
%     value - values matching time(s)
%             Returned as matrix for scalar Process [time x values],
%             otherwise as cell array
%             Failed matches return NaNs
%
% EXAMPLES
%     x = [0 1 2 4]';
%     s = SampledProcess([x,flipud(x)]);
%     v = s.valueAt(0)
%     v = s.valueAt([-1 1 3])
%     v = s.valueAt([1.2 2.5],'method','nearest')

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process
function value = valueAt(self,time,varargin)

p = inputParser;
p.KeepUnmatched = true;
p.FunctionName = 'SampledProcess ';
p.addRequired('time',@(x) isnumeric(x));
p.addOptional('method','exact',@(x) any(strcmp(x,...
   {'exact' 'linear' 'nearest' 'next' 'previous' 'spline' 'cubic'})));
p.parse(time,varargin{:});
par = p.Results;
subsetPar = p.Unmatched;

fn = fieldnames(subsetPar);
if isempty(fn)
   obj = self;
else
   obj = copy(self);
   obj.subset(subsetPar);
end

nObj = numel(obj);
if nObj == 1
   value = valueAtEach(obj,par);
else
   value = cell(nObj,1);
   for i = 1:numel(obj)
      value{i} = valueAtEach(obj(i),par);
   end
end

function v = valueAtEach(obj,par)

switch par.method
   case 'exact'
      [ind,ind2] = ismember(obj.times{1},par.time);
      v = nan(numel(par.time),obj.n);
      if any(ind)
         v(ind2(ind),:) = obj.values{1}(ind,:);
      end
   case {'linear' 'nearest' 'next' 'previous' 'spline' 'cubic'}
      v = interp1(obj.times{1},obj.values{1},par.time(:),par.method);
end
