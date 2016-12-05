function times = undoTimesOffset(self)

% Reconstruct time vector to avoid precision issues creeping in
times = cellfun(@(x,y) tvec(x(1) - y,self.dt,numel(x)),...
      self.times,num2cell(self.cumulOffset),'uni',0);
