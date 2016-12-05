% http://semver.org/
% ver is str 'major.minor.patch' or
%        array [major minor patch]
function bool = checkVersion(ver,req)

if ischar(ver)
   ver = regexp(ver,'\.','split');
end
if ischar(req)
   req = regexp(req,'\.','split');
end

assert((numel(ver)==3) && (numel(req)==3),...
   'Versions should be MAJOR.MINOR.PATCH');

if isequal(ver,req)
   bool = true;
   return;
end

for i = 1:numel(ver)
   if ver{i}>req{i}
      bool = true;
      return;
   end
end
bool = false;
