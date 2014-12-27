function f = buildFilename(path,patientID,date,data,protocol,task,condition,run,filetype)

if nargin == 1
   if isstruct(path)
      info = path;
   else
      error('Incorrect # of inputs');
   end
   for i = 1:numel(info)
      temp = struct2cell(info(i));
      [path,patientID,date,data,protocol,task,condition,run,filetype] = deal(temp{:});
      f{i,1} = buildFilename(path,patientID,date,data,protocol,task,condition,run,filetype);
   end
   return
elseif nargin == 9
   f = [patientID '_' date '_' data '_' protocol '_' task '_' condition '_' run filetype];
   f = fullfile(path,f);
end