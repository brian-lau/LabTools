% dt
% relwindow
% f for spectralProcess

function self = makeTimeCompatible(self)

method = 'linear';

[bool,relWindow,dt,t] = self.isTimeCompatible();

if bool
   return;
elseif true%relWindow && dt % relWindow & tStep
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
   keyboard
   error('not yet implemented');
end

% nt = linq(s).select(@(x) numel(x.times)).toArray;
% t = linspace(relWindow(1),relWindow(2),max(nt))';
% for i = 1:numel(s)
%    s2(i).values = interp1(s(i).times,s(i).values,t,'linear','extrap');
% end
% s = cat(3,s2.values);
% l = cat(2,l{:});