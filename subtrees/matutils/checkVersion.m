% http://semver.org/
% ver is str 'major.minor.patch' or
%        array [major minor patch]
function bool = checkVersion(ver,req)

if ischar(ver)
   c = regexp(ver,'\.','split');
   ver = sscanf(sprintf('%s#',c{:}),'%g#');
end
if ischar(req)
   c = regexp(req,'\.','split');
   req = sscanf(sprintf('%s#',c{:}),'%g#');
end

assert((numel(ver)==3) && (numel(req)==3),...
   'Versions should be MAJOR.MINOR.PATCH');

if all(ver==req)
   bool = true;
   return;
end

bool = ver > req;
for i = 1:numel(bool)
   if bool(i)
      bool = true;
      return;
   end
end
bool = false;
