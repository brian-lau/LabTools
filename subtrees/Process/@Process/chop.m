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
p.KeepUnmatched = true;
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

nWindow = size(self.window,1);
% Preallocate
obj(nWindow,1) = feval(class(self));

oldOffset = self.offset;
oldCumulOffset = self.cumulOffset;
self.offset = 0;
for i = 1:nWindow
   if par.copyInfo
      obj(i).info = copyInfo(self);
   else
      obj(i).info = self.info;
   end
   
   if par.shiftToWindow
      shift = self.window(i,1);
   else
      shift = 0;
   end
   
   % Current times become original times in new Process, removing all
   % former offsets (and window edge if requested)
   obj(i).times_ = cellfun(@(x) x - shift - oldCumulOffset(i),self.times(i,:),'uni',0);
   obj(i).times = obj(i).times_;
   obj(i).values_ = self.values(i,:);
   obj(i).values = obj(i).values_;
   obj(i).set_n();
   
   % Take current Fs, which may be different from original Fs_
   obj(i).Fs_ = self.Fs;
   obj(i).Fs = self.Fs;
   
   obj(i).tStart = self.window(i,1) - shift;
   obj(i).tEnd = self.window(i,2) - shift;
   obj(i).cumulOffset = 0;
   
   obj(i).window = self.window(i,:) - shift;
   % Bring cumulative offset back to just before the last offset
   obj(i).offset = oldCumulOffset(i) - oldOffset(i);
   % Now set the final offset
   obj(i).offset = oldOffset(i);
   
   % Take current selection
   obj(i).selection_ = self.selection_(self.selection_);
   if par.copyLabel
      obj(i).labels_ = copy(self.labels);
   else
      obj(i).labels_ = self.labels;
   end
   obj(i).quality_ = self.quality;
   obj(i).labels = obj(i).labels_;
   obj(i).quality = obj(i).quality_;
   
   obj(i).window_ = obj(i).window;
   obj(i).offset_ = self.offset_ + self.window(i,1);
end

if nargout == 0
   % Currently Matlab OOP doesn't allow the handle to be
   % reassigned, ie self = obj, so we do a silent pass-by-value
   % http://www.mathworks.com/matlabcentral/newsreader/view_thread/268574
   assignin('caller',inputname(1),obj);
end
