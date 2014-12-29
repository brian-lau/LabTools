function f = buildFilename(path,patientID,date,data,protocol,task,condition,run,filetype)

if nargin == 1
   if isstruct(path)
      info = path;
   else
      error('Incorrect # of inputs');
   end
   for i = 1:numel(info)
      temp = struct2cell(info(i));
      temp2 = '';
      for j = 1:numel(temp)
         if ~isempty(temp{j})
            if isdir(temp{j})
               temp2 = [temp{j} filesep];
            elseif strcmp(temp{j}(1),'.')
               temp2 = [temp2(1:end-1) temp{j}];
            else
               temp2 = [temp2 temp{j} '_'];
            end
         end
      end
      f{i,1} = temp2;
   end
%    for i = 1:numel(info)
%       temp = struct2cell(info(i));
%       [path,patientID,date,data,protocol,task,condition,run,filetype] = deal(temp{:});
%       f{i,1} = buildFilename(path,patientID,date,data,protocol,task,condition,run,filetype);
%    end
   return
elseif nargin == 9
   f = [patientID '_' date '_' data '_' protocol '_' task '_' condition '_' run filetype];
   f = fullfile(path,f);
end