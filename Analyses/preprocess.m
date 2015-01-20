% Preprocess raw LFP data
%
% Todo:
%   o should store rejections?
%   o allow manual rejections?
%
function preprocess(varargin)

%% Parameters
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
addParamValue(p,'run','',@isscalar);

% Preprocessing
addParamValue(p,'trim',1.5,@isscalar);
addParamValue(p,'deline',false,@islogical);

% Additional info to store in SampledProcess
addParamValue(p,'data',[]);
addParamValue(p,'dataName',@ischar);

% Saving
addParamValue(p,'overwrite',false,@islogical);

parse(p,varargin{:});
p = p.Results;

%% Matching files
info = filterFilename(fullfile(p.basedir,p.area,p.patient,p.recording));
info = filterFilename(info,'protocol',p.protocol,'task',...
   p.task,'condition',p.condition,'run',p.run,'filetype',{'.edf' '.Poly5'});
if isempty(info)
   fprintf('No files matching conditions\n');
   return;
end
files = buildFilename(info);

if ~isempty(files)
   % Savename
   ind = findstr(files{1},'_RUN');
   [~,fname] = fileparts(files{1}(1:ind-1));
   fname = [fname '_PRE'];
   
   if exist(fullfile(p.savedir,[fname '.mat']),'file') && ~p.overwrite
      fprintf('File found, skipping\n');
      return;
   end
   
   switch lower(p.task)
      case 'nothing'%{'msup'} 
            
      otherwise
      % load each run, keep as separate object
      for i = 1:numel(files)
         s(i) = loadSingleRun(files{i},'trim',p.trim,'deline',p.deline);

         % TODO: allow for each run to have different data
         if not(isempty(p.data))
            if isempty(p.dataName)
               s(i).info('data') = p.data;
            else
               s(i).info(p.dataName) = p.data;
            end
         end
      end
   end
      
   % Save
   save(fullfile(p.savedir,fname),'s');
   
   clear s;
else
   warning('requested, but not found');
end
