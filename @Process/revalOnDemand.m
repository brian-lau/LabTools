function revalOnDemand(self)

self.running_ = true;

for i = 1:size(self.queue,1)
   if self.queue{i,3}
      feval(self.queue{i,1},self,self.queue{i,2}{:});
   end
end

if self.deferredEval
   self.running_ = false;
end