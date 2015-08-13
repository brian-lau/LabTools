function isLoadable(self,~,~)

disp('checking loadability');
if ~self.isLoaded
   disp('I am loadable');
   notify(self,'loadable');
end
