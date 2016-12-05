% NEW - Create a copy of Process
%
%     obj = new(Process)
%
%     Similar to copy(Process), except that the 'info' and 'labels'
%     properties are also copied.
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% OUTPUTS
%     obj - Process
%
% EXAMPLES
%     l = metadata.Label('name','dog');
%     s = SampledProcess((1:10)','labels',l);
%     scopy = s.copy();
%     snew = s.new();
%
%     % copy is shallow, leaving labels and info referenced
%     s.labels == scopy.labels
%     % new is deep (at least for labels and info)
%     s.labels == snew.labels
%
%     s.labels.name = 'cat';
%     s.labels
%     scopy.labels
%     snew.labels
%
% SEE ALSO
%     copy

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process
function obj = new(self)

obj = copy(self);
nObj = numel(obj);
for i = 1:nObj
   obj(i).info = copyInfo(obj(i));
   obj(i).labels = copy(obj(i).labels);
end
