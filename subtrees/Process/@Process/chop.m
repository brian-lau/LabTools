% shiftToWindow
% copyInfo
% copyLabels

function obj = chop(self,varargin)

p = inputParser;
p.KeepUnmatched = true;
p.FunctionName = 'Process chop';
p.addParameter('shiftToWindow',true,@(x) islogical(x));
p.addParameter('copyInfo',true,@(x) islogical(x));
p.parse(varargin{:});
par = p.Results;

if numel(self) > 1
   error('Process:chop:InputCount',...
      'You can only chop a scalar Process.');
end

nWindow = size(self.window,1);
% Looped allocation if there is a circular reference.
% http://www.mathworks.com/support/bugreports/893538
for i = 1:nWindow
   obj(i) = feval(class(self));
end

oldOffset = self.offset;
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

   obj(i).times_ = cellfun(@(x) x-shift,self.times(i,:),'uni',0);
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
   obj(i).offset = oldOffset(i);
   
   % Take current selection
   obj(i).selection_ = self.selection_(self.selection_);
   obj(i).labels_ = self.labels;
   obj(i).quality_ = self.quality;
   obj(i).labels = self.labels;
   obj(i).quality = self.quality;
   
   obj(i).window_ = obj(i).window;
   obj(i).offset_ = self.offset_ + self.window(i,1);
end

if nargout == 0
   % Currently Matlab OOP doesn't allow the handle to be
   % reassigned, ie self = obj, so we do a silent pass-by-value
   % http://www.mathworks.com/matlabcentral/newsreader/view_thread/268574
   assignin('caller',inputname(1),obj);
end
