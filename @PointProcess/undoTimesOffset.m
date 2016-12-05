function times = undoTimesOffset(self)

times = cellfun(@(x,y) x - y,...
      self.times,num2cell(repmat(self.cumulOffset,1,self.n)),'uni',0);
