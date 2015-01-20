% TODO
% fix a set of info keys required to be present for all subjects,
% fill in defaults when an experiment does not have any

%matfile = '281013_2_CLAIVEZ_OFF.mat';
%lfpfile = 'CLANi11_2013_10_28_MSup_OFF_run2_LFP.Poly5';
% temp = linq(data)...
%    .where(@(x) numel(x.info('tCueOn'))==1)...
%    .select(@(x) x.sync(x.info('tCueOn'),'window',[-2 5])).toArray();
% 
% temp = linq(data)....
%    .where(@(x) numel(x.info('tCueOn'))==1)...
%    .select(@(x) x.sync(x.info('tCueOn'),'window',[-2 5]))...
%    .select(@(x) extract(x,'SampledProcess')).toArray();
% 
% temp2 = linq(temp)...
%    .select(@(x) x.values{1}).toArray();
function [data] = LoadExperimentReach(matfile,lfpfile,lineParam)


%% Load the topsData
log = topsDataLog.theDataLog;
log.flushAllData();
log.readDataFile(matfile);
if log.length == 0
   error('Trouble reading TOPS data log');
end
%cellfun(@(x) disp(x),log.groups)

trialInfo = log.getAllItemsFromGroupAsStruct('trialInfo');
% Trial start and finish
start = log.getAllItemsFromGroupAsStruct('traverse states:start');
ind = cellfun(@(x) isfield(x,'fevalName'),{start.item});
tStart = [start(ind).mnemonic];

finish = log.getAllItemsFromGroupAsStruct('traverse states:finish');
ind = cellfun(@(x) isfield(x,'fevalName'),{finish.item});
tFinish = [finish(ind).mnemonic];

% Fix on is the first state after start state, corresponds to the state
% just following the sync trigger
fix = log.getAllItemsFromGroupAsStruct('traverse states:enter:fix acquire');
tFixOn = [fix.mnemonic];
% fixAcquire corresponds to subject touch, which exits fix acquire
fix = log.getAllItemsFromGroupAsStruct('traverse states:exit:fix acquire');
tFixAcquire = [fix.mnemonic];
% targetOn
target = log.getAllItemsFromGroupAsStruct('traverse states:enter:overlap');
tTargetOn = [target.mnemonic];
% cueOn
cue = log.getAllItemsFromGroupAsStruct('traverse states:enter:cue2');
tCueOn = [cue.mnemonic];
% cueOff, subject leave fix window
cue = log.getAllItemsFromGroupAsStruct('traverse states:exit:cue2');
tCueOff = [cue.mnemonic];
% tarAcquireEnter, subject enters state checking target entry
tar = log.getAllItemsFromGroupAsStruct('traverse states:enter:tar acquire');
tTarAcquire1 = [tar.mnemonic];
% tarAcquireExit, subject hits target window
tar = log.getAllItemsFromGroupAsStruct('traverse states:exit:tar acquire');
tTarAcquire2 = [tar.mnemonic];

% stopOff, subject leaves hold (stop) or hold (stop) finishes
stop = log.getAllItemsFromGroupAsStruct('traverse states:exit:stop hold');
tStopHoldOff = [stop.mnemonic];

% parse timing into struct array with trial information
% Note that trialInfo gets logged after the tFinish because it occurs for
% the during the finish state.
% CHECK
%length(start) == length(finish) == length(trialInfo)
info = [trialInfo.item];
for i = 1:length(trialInfo)
   % Recall that there can be multiple fixOnsets for a given 'trial' if the
   % subject leaves fix before cue.
   ind = (tFixOn > tStart(i)) & (tFixOn < tFinish(i));
   info(i).tFixOn = tFixOn(ind);

   shift = info(i).tFixOn(1);
   info(i).tFixOn = info(i).tFixOn - shift;
   
   ind = (tFixAcquire > tStart(i)) & (tFixAcquire < tFinish(i));
   if ~any(ind)
      info(i).tFixAcquire = NaN;
   else
      info(i).tFixAcquire = tFixAcquire(ind) - shift;
   end
   
   ind = (tTargetOn > tStart(i)) & (tTargetOn < tFinish(i));
   if ~any(ind)
      info(i).tTargetOn = NaN;
   else
      info(i).tTargetOn = tTargetOn(ind) - shift;
   end

   ind = (tCueOn > tStart(i)) & (tCueOn < tFinish(i));
   if ~any(ind)
      info(i).tCueOn = NaN;
   else
      info(i).tCueOn = tCueOn(ind) - shift;
   end

   ind = (tCueOff > tStart(i)) & (tCueOff < tFinish(i));
   if ~any(ind)
      info(i).tCueOff = NaN;
   else
      info(i).tCueOff = tCueOff(ind) - shift;
   end

   ind = (tTarAcquire1 > tStart(i)) & (tTarAcquire1 < tFinish(i));
   if ~any(ind)
      info(i).tTarAcquire1 = NaN;
   else
      info(i).tTarAcquire1 = tTarAcquire1(ind) - shift;
   end
   
   ind = (tTarAcquire2 > tStart(i)) & (tTarAcquire2 < tFinish(i));
   if ~any(ind)
      info(i).tTarAcquire2 = NaN;
   else
      info(i).tTarAcquire2 = tTarAcquire2(ind) - shift;
   end
   
   ind = (tStopHoldOff > tStart(i)) & (tStopHoldOff < tFinish(i));
   if ~any(ind)
      info(i).tStopHoldOff = NaN;
   else
      info(i).tStopHoldOff = tStopHoldOff(ind) - shift;
   end
   
   info(i).tStart = tStart(i) - shift;
   info(i).tFinish = tFinish(i) - shift;
   info(i).tTrialInfo = trialInfo(i).mnemonic - shift;
end

%% add field if missing
if ~isfield(info,'stopTrial')
   info(end).stopTrial = 0;
   [info.stopTrial] = deal(0);
end

%% parse lfp file
%s = loadSingleFile(lfpfile);
signal = tms_read(lfpfile);

temp = cell2mat(signal.data(1:end))';
% Events are on the Trigger channel, and should be 100 ms. Note that the
% trigger to the LFP system is sent after trialInfo is logged on the MATLAB
% side.
events = detectEvents(signal.data{1},1/signal.fs);
labels = linq(signal.description)...
   .select(@(x) x.SignalName')...
   .where(@(x) strncmp(x,'(Lo)',4))...
   .select(@(x) x(6:end)).toList();

temp = temp(:,2:end);
if ~isempty(lineParam)
   for i = 1:size(temp,2)
      datac(:,i) = rmlinesmovingwinc(temp(:,i),...
         lineParam,...
         10,...
         struct('Fs',signal.fs,'pad',3,'fpass',[0 100],'tapers',[1.5 2]),...
         [],'n',50);
   end
%    for i = 1:size(temp,2)
%       datac(:,i) = rmlinesmovingwinc(datac(:,i),...
%          [4 1],...
%          10,...
%          struct('Fs',signal.fs,'pad',3,'fpass',[0 100],'tapers',[1.5 2]),...
%          [],'y',[64]);
%    end
end

if size(datac,1) < size(temp,1)
   n = size(temp,1);
   temp = [datac ; temp(size(datac,1)+1:end,:)];
   if size(temp,1) ~= n
      error('shwat');
   end
end

s = SampledProcess('values',temp,...
   'Fs',signal.fs,...
   'tStart',0,...
   'labels',labels(2:end));

%s.highpass(3,1000,true);
highpass(s,1.5,s.Fs*2,true);
% interpFreq(s,[50 100],2,10);
if s.Fs ~= 512
   resample(s,512);
   s = SampledProcess('values',s.values{1},...
   'Fs',512,...
   'tStart',0,...
   'labels',labels(2:end));
end
detrend(s);

window = [events(:,1) , [events(2:end,1) ; events(end,1)+15]];
%window = [events(:,2) , [events(2:end,2) ; events(end,2)+15]];

s.window = window;
s.chop();

% Crude artifact detection
values = linq(s).select(@(x) x.values{1}).toList();
values = values{:};
mv = mean(values);
stdv = std(values);
kurt = kurtosis(values);
for i = 1:numel(s)
   q = zeros(size(s(i).quality));
   ind = sum(bsxfun(@gt,s(i).values{1},100));
   if any(ind)
      q(ind>0) = q(ind>0) + 2^0;
   end
   ind = sum(bsxfun(@gt,s(i).values{1},4*kurt));
   if any(ind)
      q(ind>0) = q(ind>0) + 2^1;
   end
   ind = sum(bsxfun(@gt,s(i).values{1},5*kurt));
   if any(ind)
      q(ind>0) = q(ind>0) + 2^2;
   end
   ind = sum(bsxfun(@gt,s(i).values{1},6*kurt));
   if any(ind)
      q(ind>0) = q(ind>0) + 2^3;
   end
   ind = sum(bsxfun(@gt,s(i).values{1},7*kurt));
   if any(ind)
      q(ind>0) = q(ind>0) + 2^4;
   end
   ind = sum(bsxfun(@gt,s(i).values{1},5*stdv));
   if any(ind)
      q(ind>0) = q(ind>0) + 2^5;
   end
   ind = sum(bsxfun(@gt,s(i).values{1},6*stdv));
   if any(ind)
      q(ind>0) = q(ind>0) + 2^6;
   end
   ind = sum(bsxfun(@gt,s(i).values{1},7*stdv));
   if any(ind)
      q(ind>0) = q(ind>0) + 2^7;
   end
   ind = sum(bsxfun(@gt,s(i).values{1},8*stdv));
   if any(ind)
      disp(i)
      q(ind>0) = q(ind>0) + 2^8;
   end
   s(i).quality = q;
end

% numel(info) == numel(s) % CHECK
t1 = [info.tTrialInfo];
t2 = [s.tEnd];
n = min(numel(t1),numel(t2));
c = corr(t1(1:n-1)',t2(1:n-1)')

if c < 0.9
   keyboard
   error('Problem aligning files!');
end
if abs(numel(t1)-numel(t2)) > 2
   error('Problem aligning files!');
end
for i = 1:min(numel(s),numel(info))
   temp = containers.Map(fieldnames(info(i)),struct2cell(info(i)));
   data(i) = Segment('info',temp,'sampledProcesses',s(i));
end
