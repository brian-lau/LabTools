% dt
% relwindow
% f for spectralProcess

function self = makeTimeCompatible(self)

method = 'linear';

[bool,relWindow,dt,tBlock,t] = self.isTimeCompatible();

if bool
   return;
elseif relWindow && dt && tBlock % relWindow & tStep & tBlock
   nt = linq(self).select(@(x) numel(x.times{1})).toArray;
   
   if all(nt) == 0
      return;
   end
   
   tq = tvec(self(1).relWindow(1,1),self(1).dt,max(nt));
   for i = 1:numel(self)
      self(i).values{1} = interp1(self(i).times{1},self(i).values{1},tq,...
         method);
      self(i).times{1} = tq;
   end
else
   error('not yet implemented');
end