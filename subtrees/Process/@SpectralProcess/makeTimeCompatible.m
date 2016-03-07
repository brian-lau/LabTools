% dt
% relwindow
% f for spectralProcess

function self = makeTimeCompatible(self)

nt = linq(s).select(@(x) numel(x.times)).toArray;
t = linspace(relWindow(1),relWindow(2),max(nt))';
for i = 1:numel(s)
   s2(i).values = interp1(s(i).times,s(i).values,t,'linear','extrap');
end
s = cat(3,s2.values);
l = cat(2,l{:});