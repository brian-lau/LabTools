% LOAD CLINICAL DATA & COORDINATES?

function [s,t,params] = loadSingleRun(lfpfile,varargin)

par = inputParser;
par.KeepUnmatched = true;
addRequired(par,'lfpfile',@ischar);

% Trim data from beginning and end (after filtering)
addParameter(par,'trim',0,@isscalar);

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
      temp = cell2mat(signal.data(1:end))';
      labels = linq(signal.description);
      labels = labels.select(@(x) x.SignalName')...
         .where(@(x) strncmp(x,'(Lo)',4))...
         .select(@(x) x(6:end)).toList();
      % Skip trigger channel % TODO, find data channels by name?
      s = SampledProcess('values',temp(:,2:end),...
         'Fs',signal.fs,...
         'tStart',0,...
         'labels',labels(2:end));
      % Trigger
      t = SampledProcess('values',temp(:,1),...
         'Fs',signal.fs,...
         'tStart',0,...
         'labels','trigger');
   case '.edf'
      [hdr,values] = edfRead(lfpfile);
      labels = hdr.label;
      labels = cellfun(@(x) regexprep(x,'_','','emptymatch'),labels,'uni',false);
      [~,temp] = intersect(labels,{'01D' '12D' '23D' '01G' '12G' '23G'});
      ind = zeros(numel(labels),1);
      ind(temp) = true;
      ind = logical(ind);
      nsamples = unique(hdr.samples);
      if numel(nsamples)~=1
         error('Multiple sampling rates in edf data');
      end
      s = SampledProcess('values',values(ind,:)',...
         'Fs',1/(hdr.duration/nsamples),...
         'tStart',0,...
         'labels',labels(ind));
      t = SampledProcess('values',values(~ind,:)',...
         'Fs',1/(hdr.duration/nsamples),...
         'tStart',0,...
         'labels',labels(~ind));
   case '.txt'
      % Anne's data (text files)
      temp = load(lfpfile);
      if size(temp,2)>6
         temp = temp(:,((size(temp,2)-6)+1):end);
      end
      labels = {'01D' '12D' '23D' '01G' '12G' '23G'};
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
      beep;
      keyboard
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

if par.Results.trim
   s.window = [par.Results.trim s.window(end)-par.Results.trim];
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
params.highpass = info(h,'long'); 
%s.info('preprocessParams') = preprocessParams;