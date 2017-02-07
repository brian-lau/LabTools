% CHOP - Convert a windowed Process into an array of Processes
%
%     chop(self,varargin)
%
%     Each window is converted into a Process of the same type as input.
%     The result of chop() replaces the input variable in the workspace.
%     chop() is permanent, ie, resetting a chopped object will not return
%     it to its scalar form.
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% INPUTS
%     shiftToWindow - boolean, optional, default = True
%               boolean for shifting time so that start of each window = 0
%     copyInfo - boolean, optional, default = True
%               boolean for copying info dictionary (since it's a handle object)
%     copyLabel - boolean, optional, default = False
%               boolean for copying labels (since they're handles object)
%
% EXAMPLES
%     s = SampledProcess((1:10)','tStart',1);
%     s.window = [1 5; 6 10];
%     s.chop()

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process

function chop(self,varargin)

p = inputParser;
p.KeepUnmatched = false;
p.FunctionName = 'Process chop';
p.addParameter('shiftToWindow',true,@(x) islogical(x));
p.addParameter('copyInfo',true,@(x) islogical(x));
p.addParameter('copyLabel',false,@(x) islogical(x));
p.parse(varargin{:});
par = p.Results;

if numel(self) > 1
   error('Process:chop:InputCount',...
      'You can only chop a scalar Process.');
end

window = self.window;
nWindow = size(window,1);
oldOffset = self.offset;
oldCumulOffset = self.cumulOffset;
times = self.times;
values = self.values;

% Clear variables extracted above to minimize copy
self.times = [];
self.values = [];
self.times_ = [];
self.values_ = {};
% Flip reset bit to shortcut setters
self.reset_ = true;
% Preallocate object array to copy of original
obj(1:nWindow,1) = self;
obj = copy(obj); % Shallow copy

if par.shiftToWindow
   shift = window(:,1);
else
   shift = zeros(nWindow,1);
end

% Deal each window to one object
temp = cell(nWindow,1);
for i = 1:nWindow
   temp{i} = values(i,:);
end
[obj(:).values] = temp{:};
[obj(:).values_] = temp{:};

% Shift times
for i = 1:nWindow
   for j = 1:size(times,2)
      times{i,j} = times{i,j} - shift(i);
   end
   % Pack into cell array so we can deal to object array
   temp{i} = times(i,:);
end
[obj(:).times] = temp{:};
[obj(:).times_] = temp{:};

window = bsxfun(@minus,window,shift);
temp = num2cell(window,2);
[obj(:).window] = temp{:};
[obj(:).window_] = temp{:};
temp = num2cell(window(:,1));
[obj(:).tStart] = temp{:};
temp = num2cell(window(:,2));
[obj(:).tEnd] = temp{:};

temp = num2cell(oldOffset);
[obj(:).offset] = temp{:};
temp = num2cell(oldCumulOffset);
[obj(:).cumulOffset] = temp{:};

[obj(:).offset_] = deal(0);

% Flip reset bit back
[obj(:).reset_] = deal(false);

% Take current selection
[obj(:).selection_] = deal(self.selection_(self.selection_));
[obj(:).quality_] = obj(:).quality;

for i = 1:nWindow
   if par.copyInfo
      obj(i).info = copyInfo(self);
   end
      
   if par.copyLabel
      obj(i).labels_ = copy(self.labels);
      obj(i).labels = obj(i).labels_;
   end
end

if nargout == 0
   % Currently Matlab OOP doesn't allow the handle to be
   % reassigned, ie self = obj, so we do a silent pass-by-value
   % http://www.mathworks.com/matlabcentral/newsreader/view_thread/268574
   assignin('caller',inputname(1),obj);
end
