
function winpsd(varargin)

p = inputParser;
p.KeepUnmatched = true;
addParamValue(p,'basedir',pwd,@ischar);
addParamValue(p,'savedir',pwd,@ischar);
addParamValue(p,'area','',@ischar);
addParamValue(p,'patient','',@ischar);
addParamValue(p,'recording','',@ischar);
addParamValue(p,'protocol','',@ischar);
addParamValue(p,'task','',@ischar);
addParamValue(p,'condition','',@ischar);
%addParamValue(p,'run','',@isscalar);

% Spectrum parameters
addParamValue(p,'nw',5,@isscalar);
addParamValue(p,'winsize',4,@isscalar); % seconds
addParamValue(p,'f',[0:.25:250]',@isnumeric);

% Rejection
addParamValue(p,'detectArtifacts',true,@islogical);

% Additional info to store in SampledProcess
addParamValue(p,'data',[]);
addParamValue(p,'dataName',@ischar);

% Saving
addParamValue(p,'overwrite',false,@islogical);

parse(p,varargin{:});
p = p.Results;

% List of files matching conditions
info = filterFilename(p.basedir);
info = filterFilename(info,'patient',p.patient,'protocol',p.protocol,'task',...
   p.task,'condition',p.condition,'run','PRE');
if isempty(info)
   fprintf('No files matching conditions\n');
   return;
end
files = buildFilename(info);

if ~isempty(files)
   % Savename
   ind = findstr(files{1},'_PRE.');
   [~,fname] = fileparts(files{1}(1:ind-1));
   fname = [fname '_WINPSD'];
   
   if exist(fullfile(p.savedir,[fname '.mat']),'file') && ~p.overwrite
      fprintf('File found, skipping\n');
      return;
   end
   
   if numel(files) > 1
      error('Multiple preprocessed files?');
   else
      load(files{1});
   end
   
   P = [];
   reject = [];
   runindex = [];
   for i = 1:numel(s)
      [tempP,f,win{i}] = winpmtm(s(i),p.nw,p.f,p.winsize);
      
      s(i).window = win{i};
      [~,temp] = rejectArtifacts(s(i));
      tempReject = (temp.threshold + temp.jump + temp.muscle) > 0;
      s(i).reset;
      
      P = cat(3,P,tempP);
      reject = cat(1,reject,tempReject);
      runindex = cat(1,runindex,i*ones(size(tempP,3),1));
   end
   
   % Save
   labels = s(1).labels;
   Fs = s.Fs;
   origFs = arrayfun(@(x) x.info('preprocessParams').origFs,s);
   if not(isempty(p.data))
      if isempty(p.dataName)
         data = p.data;
         save(fullfile(p.savedir,fname),'P','win','f','p','Fs','origFs','reject','files','runindex','labels','data');
      else
         eval([p.dataName '= p.data;']);
         save(fullfile(p.savedir,fname),'P','win','f','p','Fs','origFs','reject','files','runindex','labels',p.dataName);
      end
   else
      save(fullfile(p.savedir,fname),'P','win','f','p','Fs','origFs','reject','files','runindex','labels');
   end
   
   clear win
else
   warning('requested, but not found');
end
