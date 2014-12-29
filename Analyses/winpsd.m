% area
% patient
% basedir
% experiment (MSUP,BASELINEASSIS...)

% spectrum parameters
% 
% load file
% window
% detect artifacts (use fieldtrip?
% apply spectrum
% 
% store 
% f
% time samples
% psd
% params

function winpsd(varargin)

p = inputParser;
p.KeepUnmatched = true;
addParamValue(p,'basedir','/Volumes/Data/Human/',@ischar);
addParamValue(p,'savedir',pwd,@ischar);
addParamValue(p,'area','STN',@ischar);
addParamValue(p,'patient','',@ischar);
addParamValue(p,'recording','Postop',@ischar);
addParamValue(p,'protocol','',@ischar);
addParamValue(p,'task','',@ischar);
addParamValue(p,'condition','',@ischar);
addParamValue(p,'run','',@isscalar);

% Preprocessing
addParamValue(p,'trim',1.5,@isscalar);
addParamValue(p,'deline',false,@islogical);

% Spectrum parameters
addParamValue(p,'nw',5,@isscalar);
addParamValue(p,'winsize',5,@isscalar); % seconds
addParamValue(p,'f',[0:.25:100]',@isnumeric);

% % Rejection
% addParamValue(p,'sdthresh',6,@isnumeric);
% 
% Saving
addParamValue(p,'overwrite',false,@islogical);

parse(p,varargin{:});
p = p.Results;

info = filterFilename(fullfile(p.basedir,p.area,p.patient,p.recording));
info = filterFilename(info,'protocol',p.protocol,'task',...
   p.task,'condition',p.condition,'run',p.run);

if isempty(info)
   return;
end

files = buildFilename(info);

if ~isempty(files)
   % Savename
   ind = findstr(files{1},'_RUN');
   [~,fname] = fileparts(files{1}(1:ind-1));
   fname = [fname '_WINPSD'];
   
   if exist(fullfile(p.savedir,[fname '.mat']),'file') && ~p.overwrite
      fprintf('File found, skipping\n');
      return;
   end
   
   P = [];
   reject = [];
   runindex = [];
   for i = 1:numel(files)
      s(i) = loadSingleRun(files{i},'trim',p.trim,'deline',p.deline);
      
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
   save(fullfile(p.savedir,fname),'s','P','win','f','p','reject','files','runindex','labels');
   
   clear P runindex win
else
   warning('requested, but not found');
end
