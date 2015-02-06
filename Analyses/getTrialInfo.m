function out = getTrialInfo(data)

q = linq;

temp = cell.flatten(data.extract('events'));
events = cat(1,temp{:});
temp = cell.flatten(data.extract('lfp'));
lfp = cat(1,temp{:});

tFixAcquire = q(events)...
   .select(@(x) x.find('name','fix','modality','touch').tStart).toArray;
tTargetOn = q(events)...
   .select(@(x) x.find('name','target').tStart).toArray;
tCueOn = q(events)...
   .select(@(x) x.find('name','cue').tStart).toArray;
tCueOff = q(events)...
   .select(@(x) x.find('name','cue').tEnd).toArray;
tTarAcquire = q(events)...
   .select(@(x) x.find('name','target','modality','touch').tStart).toArray;

stopTrial = q(data).select(@(x) double(x.info('trial').stopTrial)).toArray()';
failures = q(data).select(@(x) double(x.info('trial').isFailure)).toArray()';
isCorrect = q(data).select(@(x) double(x.info('trial').isCorrect)).toArray()';
isCorrect(isnan(isCorrect)) = 0;
repeats = q(data).select(@(x) double(x.info('trial').isRepeat)).toArray()';

rt = tCueOff - tCueOn;
rt(stopTrial==1) = NaN;
rt(failures>0) = NaN;

mt = tTarAcquire - tCueOff;
mt(stopTrial==1) = NaN;
mt(failures>0) = NaN;

% average go reaction time after stop
%goInd = find(~stopTrial & ~repeats & isCorrect); % index of go trials
goInd = find(~stopTrial & isCorrect); % index of go trials
stopInd = find(stopTrial); % index of stop trials
goback = goInd - 1; % index of trials 1 trial before a go trial
stopGoInd = ismember(goback,stopInd); % index of go trials with stop 1 back
stopGoInd = goInd(stopGoInd);
goGoInd = ismember(goback,goInd); % index of go trials with go 1 back
goGoInd = goInd(goGoInd);

% double check
% stopTrial(stopGoInd - 1) % all 1
% stopTrial(stopGoInd) % all 0
% ~stopTrial(goGoInd - 1) % all 1
% ~stopTrial(goGoInd) % all 1

% Convert to boolean vector (logical)
temp = zeros(numel(data),1);
temp(stopGoInd) = 1;
stopGoInd = logical(temp);
temp = zeros(numel(data),1);
temp(goGoInd) = 1;
goGoInd = logical(temp);
temp = zeros(numel(data),1);
temp(goInd) = 1;
goInd = logical(temp);

colTar = q(data).select(@(x) x.info('trial').current).toList()';
indTarCol = strcmp(colTar,'pink');
posTar = q(data).select(@(x) x.info('trial').posTar).toList()';
posTar = cat(1,posTar{:});
indTarLeft = posTar(:,1)<0;

out.tFixAcq = tFixAcquire;
%for i = 1:numel(tTargetOn)
%   out.tTarOn(i) = tTargetOn{i}(end);
%end
out.tTarOn = tTargetOn;
out.tCueOn = tCueOn;
out.tCueOff = tCueOff;
out.tTarAcq = tTarAcquire;
out.isStop = stopTrial;
out.isCorrect = isCorrect;
out.isFailure = failures;
out.isRepeat = repeats;
out.isGo = goInd;
out.isGoGo = goGoInd;
out.isStopGo = stopGoInd;
out.tarCol = indTarCol;
out.isTarLeft = indTarLeft;
temp = linq(lfp).select(@(x) x.quality).toList';
out.quality = cat(1,temp{:});
out.rt = rt;
out.mt = mt;

nanmean(mt(out.isGoGo))
nanmean(mt(out.isStopGo))
nanmean(mt(out.isGo))

nanmean(rt(out.isGoGo))
nanmean(rt(out.isStopGo))
nanmean(rt(out.isGo))