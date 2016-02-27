function disableSegmentListeners(self)

for i = 1:numel(self)
   if ~isempty(self(i).segment)
      if self(i).segment.coordinateProcesses
         [self(i).segment.listeners_.offset.Enabled] = deal(false);
         [self(i).segment.listeners_.window.Enabled] = deal(false);
         [self(i).segment.listeners_.sync.Enabled] = deal(false);
      end
   end
end