% FIX - Make permanent current data transformations
%
%     fix(Process,varargin);
%
%     Default behavior is *not* to fix window/offset properties. This means
%     that while values are fixed, resetting will return the Process to the
%     same timebase as the original Process.
%
%     When input is an array of Processes, will iterate and fix each.
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% INPUTS
%     shiftToWindow - boolean, optional, default = False
%               boolean for storing current offset/window as permanent
%               this will also change tStart/tEnd
%
% EXAMPLES
%     p = PointProcess('times',{(1:2)' (6:10)' (11:20)'},'quality',[0 1 1]);
%     p.subset(2) % channel 2 by index
%     p.fix(); % keep this selection as permanent
%
%     s = SampledProcess((1:10)');
%     s.window = [5 10];
%     s.offset = 10;
%     s.fix(); % keep window selection as permanent, but offset is not
%     plot(s.reset); 
%
%     s = SampledProcess((1:10)');
%     s.window = [5 10];
%     s.offset = 10;
%     s.fix('shiftToWindow',true); % keep window selection & offset as permanent
%     plot(s.reset);

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process

function self = fix(self,varargin)

p = inputParser;
p.KeepUnmatched = false;
p.FunctionName = 'Process fix';
p.addParameter('shiftToWindow',false,@(x) islogical(x));
p.parse(varargin{:});
par = p.Results;

for i = 1:numel(self)
   if size(self(i).window,1) > 1
      error('Process:fix:InputFormat',...
         'fix() works exclusively with single windows');
   end
   
   self(i).Fs_ = self(i).Fs;
   self(i).labels_ = self(i).labels;
   self(i).quality_ = self(i).quality;
   self(i).selection_ = self(i).selection_(self(i).selection_);

   self(i).times_ = undoTimesOffset(self(i));
   self(i).values_ = self(i).values;
   
   if par.shiftToWindow
      self(i).reset_ = true;
      self(i).offset_ = self(i).cumulOffset;
      self(i).cumulOffset = self(i).offset;
      self(i).window_ = self(i).window;
      self(i).window = self(i).window_;
      if self(i).relWindow(1) > self(i).tEnd
         self(i).tEnd = self(i).relWindow(2);
         self(i).tStart = self(i).relWindow(1);
      else
         self(i).tStart = self(i).relWindow(1);
         self(i).tEnd = self(i).relWindow(2);
      end
      self(i).reset_ = false;
   end
   
   self(i).set_n();
end