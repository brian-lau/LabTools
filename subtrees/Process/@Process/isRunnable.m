function isRunnable(self,~,~)

if self.lazyLoad
   isLoadable(self);
end
disp('checking runnability');
if isempty(self.chain)
elseif any(~[self.chain{:,3}]);
   disp('I am runnable');
   notify(self,'runnable');
end
