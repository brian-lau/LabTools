% FIX - Make permanent current data transformations
%
%     fix(Process);
%
%     tStart/tEnd are not affected, which may affect window validity.
%     offset is set to zero
%
%     When input is an array of Processes, will iterate and fix each.
%
% EXAMPLES
%     p = PointProcess('times',{(1:2)' (6:10)' (11:20)'},'quality',[0 1 1]);
%     p.subset(2) % channel 2 by index
%     p.fix(); % keep this selection as permanent

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process

function self = fix(self)

for i = 1:numel(self)
   self(i).Fs_ = self(i).Fs;
   self(i).quality_ = self(i).quality;
   self(i).selection_ = self(i).selection_(self(i).selection_);
   self(i).labels_ = self(i).labels;
   self(i).times_ = self.times;
   self(i).values_ = self(i).values;
   self(i).window_ = self(i).relWindow;
   self(i).offset_ = 0;
   self(i).offset = 0;
   self(i).cumulOffset = self(i).offset;
   self(i).set_n();
end
