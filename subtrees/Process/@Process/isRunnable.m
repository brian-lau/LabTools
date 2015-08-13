function isRunnable(self,~,~)

if self.lazyLoad
   isLoadable(self);
end
disp('checking runnability');
if isempty(self.queue)
elseif any(~[self.queue{:,3}]);
   disp('I am runnable');
   notify(self,'runnable');
end
