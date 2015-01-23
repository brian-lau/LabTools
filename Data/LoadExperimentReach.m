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
function [data] = LoadExperimentReach(matfile,lfpfile)


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
% cueOff, subject leave fix window, this is also fixOff
cue = log.getAllItemsFromGroupAsStruct('traverse states:exit:cue2');
tCueOff = [cue.mnemonic];
% tarAcquireEnter, subject enters state checking target entry
tar = log.getAllItemsFromGroupAsStruct('traverse states:enter:tar acquire');
tTarAcquire1 = [tar.mnemonic];
% tarAcquireExit, subject hits target window
tar = log.getAllItemsFromGroupAsStruct('traverse states:exit:tar acquire');
tTarAcquire2 = [tar.mnemonic];
% tarHoldExit, subject  target window
tar = log.getAllItemsFromGroupAsStruct('traverse states:exit:target hold');
tTarHold = [tar.mnemonic];

% stopOff, subject leaves hold (stop) or hold (stop) finishes
stop = log.getAllItemsFromGroupAsStruct('traverse states:exit:stop hold');
tStopHoldOff = [stop.mnemonic];

success = log.getAllItemsFromGroupAsStruct('traverse states:enter:success');
tSuccessEnter = [success.mnemonic];
success = log.getAllItemsFromGroupAsStruct('traverse states:exit:success');
tSuccessExit = [success.mnemonic];
success2 = log.getAllItemsFromGroupAsStruct('traverse states:enter:success2');
tSuccess2Enter = [success2.mnemonic];
success2 = log.getAllItemsFromGroupAsStruct('traverse states:exit:success2');
tSuccess2Exit = [success2.mnemonic];
failure = log.getAllItemsFromGroupAsStruct('traverse states:enter:failure');
tFailure = [failure.mnemonic];
abort = log.getAllItemsFromGroupAsStruct('traverse states:enter:abort');
tAbort = [abort.mnemonic];

% parse timing into struct array with trial information
% Note that trialInfo gets logged after the tFinish because it occurs for
% the during the finish state.

for i = 1:numel(trialInfo)
   meta_trial(i) = metadata.trial.Msup(trialInfo(i).item);
   if isempty(meta_trial(i).stopTrial)
      meta_trial(i).stopTrial = false;
   end
   % Recall that there can be multiple fixOnsets for a given 'trial' if the
   % subject leaves fix before cue.
   ind = (tFixOn > tStart(i)) & (tFixOn < tFinish(i));
   tOn = tFixOn(ind);
   
   shift = tOn(1); % Beginning of trial
   %% Fix point
   tOn = tOn - shift;   
   if meta_trial(i).stopTrial
      meta_trial(i).isSuccess = true;
      meta_trial(i).isFailure = false;
      meta_trial(i).isAbort = false;
      if meta_trial(i).isCorrect
         ind = (tSuccess2Exit > tStart(i)) & (tSuccess2Exit < tFinish(i));
         tOff = tSuccess2Exit(ind) - shift;
      else
         ind = (tStopHoldOff > tStart(i)) & (tStopHoldOff < tFinish(i));
         tOff = tStopHoldOff(ind) - shift;         
      end
   else
      if numel(tOn) >= 1
         % if success
         ind = (tSuccessEnter > tStart(i)) & (tSuccessEnter < tFinish(i));
         if sum(ind) == 1
            tOff = tCueOff((tCueOff > tStart(i)) & (tCueOff < tFinish(i))) - shift;
            meta_trial(i).isSuccess = true;
            meta_trial(i).isFailure = false;
            meta_trial(i).isAbort = false;
         elseif sum(ind) > 1
            error('should not happen');
         else
            % else failure or abort, in which case all stim off here
            indF = (tFailure > tStart(i)) & (tFailure < tFinish(i));
            indA = (tAbort > tStart(i)) & (tAbort < tFinish(i));
            if sum(indF) == 1
               tOff = tFailure(indF) - shift;
               meta_trial(i).isSuccess = false;
               meta_trial(i).isFailure = true;
               meta_trial(i).isAbort = false;
            elseif sum(indA) == 1
               tOff = tAbort(indF) - shift;
               meta_trial(i).isSuccess = false;
               meta_trial(i).isFailure = false;
               meta_trial(i).isAbort = true;
            else
               error('should not happen');
            end
         end
      end
   end
   if numel(tOn) > 1
      meta_trial(i).isRepeat = numel(tOn);
      tOn = tOn(end);
   else
      meta_trial(i).isRepeat = 0;
   end
   meta_fixation(i) = metadata.event.Stimulus('name','fix','time',tOn,...
      'duration',tOff-tOn);

   %% TARGET
   tOn = tTargetOn((tTargetOn > tStart(i)) & (tTargetOn < tFinish(i))) - shift;
   if numel(tOn) >= 1
      if meta_trial(i).stopTrial
         if meta_trial(i).isCorrect
            ind = (tSuccess2Enter > tStart(i)) & (tSuccess2Enter < tFinish(i));
            tOff = tSuccess2Enter(ind) - shift;
         else
            ind = (tStopHoldOff > tStart(i)) & (tStopHoldOff < tFinish(i));
            tOff = tStopHoldOff(ind) - shift;
         end
      else
         if meta_trial(i).isSuccess
            tOff = tTarHold((tTarHold > tStart(i)) & (tTarHold < tFinish(i))) - shift;
         elseif meta_trial(i).isFailure
            indF = (tFailure > tStart(i)) & (tFailure < tFinish(i));
            tOff = tFailure(indF) - shift;
         elseif meta_trial(i).isAbort
            indA = (tAbort > tStart(i)) & (tAbort < tFinish(i));
            tOff = tAbort(indF) - shift;
         end
      end
      if meta_trial(i).isRepeat
         tOn = tOn(end);
      end
      meta_target(i) = metadata.event.Stimulus('name','target','time',tOn,...
         'duration',tOff-tOn);
   else % targets never displayed
      meta_target(i) = metadata.event.Stimulus('name','target','time',NaN,...
         'duration',NaN);
   end
   
   %% FEEDBACK?
   if meta_trial(i).stopTrial
      tOn = tSuccess2Enter((tSuccess2Enter > tStart(i)) & (tSuccess2Enter < tFinish(i))) - shift;
   else
      tOn = tSuccessEnter((tSuccessEnter > tStart(i)) & (tSuccessEnter < tFinish(i))) - shift;
   end
   if numel(tOn) >= 1
      if meta_trial(i).stopTrial
         if meta_trial(i).isCorrect
            ind = (tSuccess2Exit > tStart(i)) & (tSuccess2Exit < tFinish(i));
            tOff = tSuccess2Exit(ind) - shift;
         else
            ind = (tStopHoldOff > tStart(i)) & (tStopHoldOff < tFinish(i));
            tOff = tStopHoldOff(ind) - shift;
         end
      else
         if meta_trial(i).isSuccess
            tOff = tSuccessExit((tSuccessExit > tStart(i)) & (tSuccessExit < tFinish(i))) - shift;
         elseif meta_trial(i).isFailure
            indF = (tFailure > tStart(i)) & (tFailure < tFinish(i));
            tOff = tFailure(indF) - shift;
         elseif meta_trial(i).isAbort
            indA = (tAbort > tStart(i)) & (tAbort < tFinish(i));
            tOff = tAbort(indF) - shift;
         end
      end
      if meta_trial(i).isRepeat
         tOn = tOn(end);
      end
      meta_feedback(i) = metadata.event.Stimulus('name','feedback','time',tOn,...
         'duration',tOff-tOn);
   else % targets never displayed
      meta_feedback(i) = metadata.event.Stimulus('name','feedback','time',NaN,...
         'duration',NaN);
   end
   
   %% CUE
   tOn = tCueOn((tCueOn > tStart(i)) & (tCueOn < tFinish(i))) - shift;
   if numel(tOn) >= 1
      tOff = tCueOff((tCueOff > tStart(i)) & (tCueOff < tFinish(i))) - shift;
      if meta_trial(i).isRepeat
         tOn = tOn(end);
      end
      meta_cue(i) = metadata.event.Stimulus('name','cue','time',tOn,...
         'duration',tOff-tOn);
   else
      meta_cue(i) = metadata.event.Stimulus('name','cue','time',NaN,...
         'duration',NaN);
   end
   
   %% fix touch
   tOn = tFixAcquire((tFixAcquire > tStart(i)) & (tFixAcquire < tFinish(i))) - shift;
   if (numel(tOn) >= 1) && meta_trial(i).isSuccess
      tOff = tCueOff((tCueOff > tStart(i)) & (tCueOff < tFinish(i))) - shift;
      if meta_trial(i).isRepeat
         tOn = tOn(end);
      end
      meta_fixTouch(i) = metadata.event.Response('name','fix','modality','touch',...
         'time',tOn,'duration',tOff-tOn);
   else
      meta_fixTouch(i) = metadata.event.Response('name','fix','modality','touch',...
         'time',NaN,'duration',NaN);
   end
    
   %% target touch
   tOn = tTarAcquire2((tTarAcquire2 > tStart(i)) & (tTarAcquire2 < tFinish(i))) - shift;
   if numel(tOn) >= 1
      tOff = tTarHold((tTarHold > tStart(i)) & (tTarHold < tFinish(i))) - shift;
      if meta_trial(i).isRepeat
         tOn = tOn(end);
      end
      meta_tarTouch(i) = metadata.event.Response('name','target','modality','touch',...
         'time',tOn,'duration',tOff-tOn);
   else
      meta_tarTouch(i) = metadata.event.Response('name','target','modality','touch',...
         'time',NaN,'duration',NaN);
   end
   
end

% info = [trialInfo.item];
% for i = 1:length(trialInfo)
%    % Recall that there can be multiple fixOnsets for a given 'trial' if the
%    % subject leaves fix before cue.
%    ind = (tFixOn > tStart(i)) & (tFixOn < tFinish(i));
%    info(i).tFixOn = tFixOn(ind);
% 
%    shift = info(i).tFixOn(1);
%    info(i).tFixOn = info(i).tFixOn - shift;
%    
%    ind = (tFixAcquire > tStart(i)) & (tFixAcquire < tFinish(i));
%    if ~any(ind)
%       info(i).tFixAcquire = NaN;
%    else
%       info(i).tFixAcquire = tFixAcquire(ind) - shift;
%    end
%    
%    ind = (tTargetOn > tStart(i)) & (tTargetOn < tFinish(i));
%    if ~any(ind)
%       info(i).tTargetOn = NaN;
%    else
%       info(i).tTargetOn = tTargetOn(ind) - shift;
%    end
% 
%    ind = (tCueOn > tStart(i)) & (tCueOn < tFinish(i));
%    if ~any(ind)
%       info(i).tCueOn = NaN;
%    else
%       info(i).tCueOn = tCueOn(ind) - shift;
%    end
% 
%    ind = (tCueOff > tStart(i)) & (tCueOff < tFinish(i));
%    if ~any(ind)
%       info(i).tCueOff = NaN;
%    else
%       info(i).tCueOff = tCueOff(ind) - shift;
%    end
% 
%    ind = (tTarAcquire1 > tStart(i)) & (tTarAcquire1 < tFinish(i));
%    if ~any(ind)
%       info(i).tTarAcquire1 = NaN;
%    else
%       info(i).tTarAcquire1 = tTarAcquire1(ind) - shift;
%    end
%    
%    ind = (tTarAcquire2 > tStart(i)) & (tTarAcquire2 < tFinish(i));
%    if ~any(ind)
%       info(i).tTarAcquire2 = NaN;
%    else
%       info(i).tTarAcquire2 = tTarAcquire2(ind) - shift;
%    end
%    
%    ind = (tStopHoldOff > tStart(i)) & (tStopHoldOff < tFinish(i));
%    if ~any(ind)
%       info(i).tStopHoldOff = NaN;
%    else
%       info(i).tStopHoldOff = tStopHoldOff(ind) - shift;
%    end
%    
%    info(i).tStart = tStart(i) - shift;
%    info(i).tFinish = tFinish(i) - shift;
%    info(i).tTrialInfo = trialInfo(i).mnemonic - shift;
% end
% 
% %% add field if missing
% if ~isfield(info,'stopTrial')
%    info(end).stopTrial = 0;
%    [info.stopTrial] = deal(0);
% end

%% parse lfp file
[s,t] = loadSingleRun(lfpfile);

% Events are on the Trigger channel, and should be 100 ms. Note that the
% trigger to the LFP system is sent after trialInfo is logged on the MATLAB
% side.
events = sig.detectEvents(t.values{1},1/t.Fs);

window = [events(:,1) , [events(2:end,1) ; events(end,1)+15]];
s.window = window;
s.chop();

t1 = [info.tTrialInfo];
t2 = [s.tEnd];
n = min(numel(t1),numel(t2));
c = corr(t1(1:n-1)',t2(1:n-1)')

if c < 0.9
   error('Problem aligning files!');
end
% numel(info) == numel(s) % CHECK
if abs(numel(t1)-numel(t2)) > 2
   error('Problem aligning files!');
end
keyboard
% Pack into Segment
for i = 1:min(numel(s),numel(info))
   temp = containers.Map('trial',meta_trial(i));
   events = EventProcess('events',[meta_fixation(i) meta_target(i) meta_cue(i)...
      meta_feedback(i) meta_fixTouch(i) meta_tarTouch(i)]);
   data(i) = Segment('info',temp,'SampledProcesses',s(i),'EventProcesses',events);
end


