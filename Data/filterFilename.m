function info = filterFilename(info,varargin)

p = inputParser;
p.KeepUnmatched = false;
addParamValue(p,'patient','',@(x) ischar(x) || iscell(x));
addParamValue(p,'protocol','',@(x) ischar(x) || iscell(x));
addParamValue(p,'task','',@(x) ischar(x) || iscell(x));
addParamValue(p,'condition','',@(x) ischar(x) || iscell(x));
addParamValue(p,'run','',@(x) ischar(x) || iscell(x));
addParamValue(p,'filetype','',@(x) ischar(x) || iscell(x));
parse(p,varargin{:});
p = p.Results;

if ~isstruct(info)
   if isdir(info)
      path = info;
      f = dir(path);
      info = parseFilename({f.name});
      for j = 1:numel(info)
         info(j).path = path;
      end
   end
end

% Drop files w/out patientID
query = linq(info);
query.where(@(x) ~isempty(x.patientID)).select(@(x) x);

if ~isempty(p.patient) && (query.count>0)
   query.where(@(x) any(strcmp(x.patientID,p.patient))).select(@(x) x);
end

if ~isempty(p.protocol) && (query.count>0)
   query.where(@(x) any(strcmp(x.protocol,p.protocol))).select(@(x) x);
end

if ~isempty(p.task) && (query.count>0)
   query.where(@(x) any(strcmp(x.task,p.task))).select(@(x) x);
end

if ~isempty(p.condition) && (query.count>0)
   query.where(@(x) any(strcmp(x.condition,p.condition))).select(@(x) x);
end

if ~isempty(p.filetype) && (query.count>0)
   query.where(@(x) any(strcmp(x.filetype,p.filetype))).select(@(x) x);
end

if query.count > 0
   info = query.toArray();
else
   info = [];
end