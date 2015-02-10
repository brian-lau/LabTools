function [pLavg,pRavg,pLbrown,pRbrown] = getPower(m,indTask)

indPatient = 1:size(m,1);

indCondition = 1; %OFF
% Baseline off left
peakLocLoff = cat(1,m(indPatient,indTask,indCondition).L_peakLoc); % peak location/channel
peakMagLoff = cat(1,m(indPatient,indTask,indCondition).L_peakMag); % peak power/channel
truePeakLoff = cat(1,m(indPatient,indTask,indCondition).L_truePeak); % bool for true peak vs. edge
bandmaxLoff = cat(1,m(indPatient,indTask,indCondition).L_bandmax); % index for max power in band (edge inclusive)
bandavgLoff = cat(1,m(indPatient,indTask,indCondition).L_bandavg); % average power in band
offavgLoff = cat(1,m(indPatient,indTask,indCondition).L_offavg); % avg power in 10 hz band around peak freq found in off condition

maxtrueL = bandmaxLoff.*truePeakLoff; % mask where peak in off is a real peak (not edge)
maxtrueL(isnan(maxtrueL)) = 0; % zero nans (which mark where we don't have data)
maxtrueL = logical(maxtrueL); % booleanize

indCondition = 2; %ON
% Baseline on left
offavgLon = cat(1,m(indPatient,indTask,indCondition).L_offavg); % avg power around off defined peak
bandavgLon = cat(1,m(indPatient,indTask,indCondition).L_bandavg);

indCondition = 1; %OFF
% Baseline off right
peakLocRoff = cat(1,m(indPatient,indTask,indCondition).R_peakLoc);
peakMagRoff = cat(1,m(indPatient,indTask,indCondition).R_peakMag);
truePeakRoff = cat(1,m(indPatient,indTask,indCondition).R_truePeak);
bandmaxRoff = cat(1,m(indPatient,indTask,indCondition).R_bandmax);
bandavgRoff = cat(1,m(indPatient,indTask,indCondition).R_bandavg);
offavgRoff = cat(1,m(indPatient,indTask,indCondition).R_offavg);

maxtrueR = bandmaxRoff.*truePeakRoff; % this is relative to OFF condition
maxtrueR(isnan(maxtrueR)) = 0;
maxtrueR = logical(maxtrueR);

indCondition = 2; %ON
% Baseline on right
offavgRon = cat(1,m(indPatient,indTask,indCondition).R_offavg);
bandavgRon = cat(1,m(indPatient,indTask,indCondition).R_bandavg);

% normalized power for each channel, in the band requested
% this yeilds 3 numbers for each side
pLavg = 100*(bandavgLoff-bandavgLon)./bandavgLoff;
pRavg = 100*(bandavgRoff-bandavgRon)./bandavgRoff;

% normalized power, picking one contact with Brown's method for each side
indOff = (offavgLoff.*maxtrueL)>0; % index where we have true peaks off
indOn = (offavgLon.*maxtrueL)>0;% index where we have true peaks on, may differ from above from missing data
pLoff = sum(offavgLoff.*indOff,2); % mask, then sum to vector (ok, cause zeros mark missing data)
pLon = sum(offavgLon.*indOn,2);


indOff = (offavgRoff.*maxtrueR)>0;
indOn = (offavgRon.*maxtrueR)>0;
pRoff = sum(offavgRoff.*indOff,2);
pRon = sum(offavgRon.*indOn,2);

pLbrown = 100*(pLoff-pLon)./pLoff;
pRbrown = 100*(pRoff-pRon)./pRoff;
