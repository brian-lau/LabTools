% Determine whether we can queue
% Running w/out history:
%     running_ = 1, deferredEval = 0, history = 0
% Running w/ history:
%     running_ = 1, deferredEval = 0, history = 1
% Running w/ deferral (run called explicitly):
%     running_ = 1, deferredEval = 1, history = 1
% Running w/ deferral (before run called explicitly):
%     running_ = 0, deferredEval = 1, history = 1
function bool = isQueueable(self)

bool = self.history && (~self.running_ || ~self.deferredEval);
