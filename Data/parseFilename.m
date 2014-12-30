function info = parseFilename(f)

if iscell(f)
   for i = 1:numel(f)
      info(i) = parseFilename(f{i});
   end
   return
end

[path,name,ext] = fileparts(f);

%C = strsplit(name,'_');
C = regexp(name,'_','split');

if numel(C) == 6
   info.path = path;
   info.patientID = C{1};
   info.date = C{2};
   info.data = C{3};
   info.protocol = C{4};
   info.task = C{5};
   info.condition = '';
   info.run = C{6};
   info.filetype = ext;
elseif numel(C) == 7
   info.path = path;
   info.patientID = C{1};
   info.date = C{2};
   info.data = C{3};
   info.protocol = C{4};
   info.task = C{5};
   info.condition = C{6};
   info.run = C{7};
   info.filetype = ext;
else
   info.path = '';
   info.patientID = '';
   info.date = '';
   info.data = '';
   info.protocol = '';
   info.task = '';
   info.condition = '';
   info.run = '';
   info.filetype = '';
end
