% LOAD CLINICAL DATA & COORDINATES?

function [s,t,params] = loadSingleRun(lfpfile,varargin)

par = inputParser;
par.KeepUnmatched = true;
addRequired(par,'lfpfile',@ischar);

% Trim data from beginning and end (after filtering)
addParameter(par,'trim',0,@(x) isscalar(x) || (numel(x)==2));

% Remove line noise
addParameter(par,'deline',false,@islogical);
% removePLI parameters
addParameter(par,'M',5,@isscalar);
addParameter(par,'B',[50 .2 4],@(x) isnumeric(x) && (numel(x)==3));
addParameter(par,'P',[0.01 4 4],@(x) isnumeric(x) && (numel(x)==3));
addParameter(par,'W',2,@isscalar);

% threshold
addParameter(par,'threshold',300,@isscalar);

% Highpass filter cutoff, 0 skips highpass filtering
addParameter(par,'Fpass',1.5,@isscalar);
addParameter(par,'Fstop',0.01,@isscalar);

% detrend

% resample
addParameter(par,'resample',512,@isscalar);

parse(par,lfpfile,varargin{:});

%% Load raw data
[path,file,ext] = fileparts(lfpfile);

switch lower(ext)
   case '.poly5'
      signal = tms_read(lfpfile);
      
      % Catch empty data
      ind = cellfun(@isempty,signal.data);
      if any(ind)
         n = cellfun(@numel,signal.data);
         un = unique(n);
         if numel(un) > 2
            error('Mismatched signal lengths???');
         end
         n = max(n);
         % Fill with empty (maybe should be NaNs?)
         signal.data{ind} = zeros(1,n);
      end
      temp = cell2mat(signal.data(1:end))';
       
      tags = linq(signal.description);
      tags = tags.select(@(x) x.SignalName')...
         .where(@(x) strncmp(x,'(Lo)',4))...
         .select(@(x) x(6:end)).toList();
      % Skip trigger channel
      ind = ~strcmp(tags,'Trigger');
      tags = tags(ind);
      
      for i = 1:numel(tags)
         labels(i) = metadata.label.dbsDipole(tags{i});
      end
  
      s = SampledProcess('values',temp(:,ind),...
         'Fs',signal.fs,...
         'tStart',0,...
         'labels',labels);

      % Trigger
      t = SampledProcess('values',temp(:,~ind),...
         'Fs',signal.fs,...
         'tStart',0,...
         'labels','trigger');
   case '.edf'
      [hdr,values] = edfRead(lfpfile);
      tags = hdr.label;
      tags = cellfun(@(x) regexprep(x,'_','','emptymatch'),tags,'uni',false);
      [~,temp] = intersect(tags,{'01D' '12D' '23D' '01G' '12G' '23G'});
      ind = zeros(numel(tags),1);
      ind(temp) = true;
      ind = logical(ind);
      nsamples = unique(hdr.samples);
      if numel(nsamples)~=1
         error('Multiple sampling rates in edf data');
      end
      for i = 1:numel(tags)
         if ind(i)
            labels(i) = metadata.label.dbsDipole(tags{i});
         end
      end
      s = SampledProcess('values',values(ind,:)',...
         'Fs',1/(hdr.duration/nsamples),...
         'tStart',0,...
         'labels',labels(ind));
      t = SampledProcess('values',values(~ind,:)',...
         'Fs',1/(hdr.duration/nsamples),...
         'tStart',0,...
         'labels',tags(~ind));
   case '.txt'
      % Anne's data (text files)
      temp = load(lfpfile);
      if size(temp,2)>6
         temp = temp(:,((size(temp,2)-6)+1):end);
      end
      tags = {'01D' '12D' '23D' '01G' '12G' '23G'};
      for i = 1:numel(tags)
         labels(i) = metadata.label.dbsDipole(tags{i});
      end
      s = SampledProcess('values',temp,...
         'Fs',512,...
         'tStart',0,...
         'labels',labels);
   otherwise
      error('Unknown file type');
end

if par.Results.threshold
   fprintf('Thresholding\n');
   s.clip(par.Results.threshold,'method','abs');
end

if par.Results.Fpass
   fprintf('Highpass filtering\n');
   try
      load('/Users/brian/Documents/Code/Repos/LabAnalyses/FIR_highpass.mat');
      i = Fs == s.Fs;
      j = Fpass == par.Results.Fpass;
      k = Fstop == par.Results.Fstop;
      fprintf('\tUsing cached filter\n');
      tic;
      s.filter(h(i,j,k));
      h = h(i,j,k);
      toc
   catch
      fprintf('\tBuilding filter anew\n');
      beep; %keyboard
      tic;
      [~,h,d] = highpass(s,'Fpass',par.Results.Fpass,'Fstop',par.Results.Fstop);
      toc
   end
end

if par.Results.deline
   fprintf('Removing line noise\n');
   M = par.Results.M;
   B = par.Results.B;
   P = par.Results.P;
   W = par.Results.W;
   f = @(x) removePLI_multichan(x',s.Fs,M,B,P,W,50,0);
   s.map(@(x) f(x)');
end

if any(par.Results.trim>0)
   if numel(par.Results.trim) == 2
      s.window = [par.Results.trim(1) s.window(end)-par.Results.trim(2)];
   else
      s.window = [par.Results.trim s.window(end)-par.Results.trim];
   end
   s.chop();
end   

if (par.Results.resample < s.Fs) && par.Results.resample
   fprintf('Resampling\n');
   origFs = s.Fs;
   s.resample(par.Results.resample);
   if exist('t','var')
      t.resample(par.Results.resample);
   end
else
   origFs = s.Fs;
end

fix(s);

params = par.Results;
params.origFs = origFs;
if par.Results.Fpass
   params.highpass = info(h,'long');
else
   params.highpass = [];
end
%s.info('preprocessParams') = preprocessParams;