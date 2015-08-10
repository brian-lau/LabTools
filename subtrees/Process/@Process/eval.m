function eval(self)

if any(cellfun(@(x) ~x{3},self.chain))
   self.running = true;
   for i = 1:numel(self.chain)
      if ~self.chain{i}{3}
         feval(self.chain{i}{1},self,self.chain{i}{2}{:});
         self.chain{i}{3} = true;
      end
   end
   self.running = false;
end
