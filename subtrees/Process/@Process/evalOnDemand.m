function evalOnDemand(self,varargin)

self.running_ = true;
disp('running')
for i = 1:size(self.chain,1)
   if ~self.chain{i,3}
      feval(self.chain{i,1},self,self.chain{i,2}{:});
      self.chain{i,3} = true;
   end
end

self.running_ = false;
