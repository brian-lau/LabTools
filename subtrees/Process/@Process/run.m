% Immediately flush any pending method calls in queue

function self = run(self,varargin)

notify(self,'runImmediately');