function [out,clinic] = winpsdstats(varargin)

par = inputParser;
par.KeepUnmatched = true;
addParamValue(par,'basedir',pwd,@ischar);
addParamValue(par,'savedir',pwd,@ischar);
addParamValue(par,'area','STN',@ischar);
addParamValue(par,'patient','',@ischar);
addParamValue(par,'recording','Postop',@ischar);
addParamValue(par,'protocol','',@ischar);
addParamValue(par,'task','',@ischar);
addParamValue(par,'condition','',@ischar);
addParamValue(par,'run','',@isscalar);

% normalization
addParamValue(par,'normalize',true,@islogical);
addParamValue(par,'normalize_range',[100 200],@isnumeric);

band_beta = [8 35];

parse(par,varargin{:});
par = par.Results;

info = filterFilename(par.basedir);
info = filterFilename(info,'patient',par.patient,'protocol',par.protocol,'task',...
   par.task,'condition',par.condition,'filetype','.mat','run','WINPSD');
if isempty(info)
   out = [];
   clinic = [];
   return;
end
fnames = unique(buildFilename(info));

for i = 1:numel(fnames)
   load(fnames{i});

   P2 = P;
   rejectNaN = reject;
   rejectNaN(reject==1) = NaN;
   rejectNaN(reject==0) = 1;
   for j = 1:numel(f)
      %P2(j,:,:) = squeeze(P(j,:,:)).*(1-reject');
      P2(j,:,:) = squeeze(P(j,:,:)).*rejectNaN';
   end
   P = P2;
   
   ind = ismember(labels,{'01G' '12G' '23G'});
   meanP = nanmean(P(:,ind,:),3);
   if par.normalize
      ind2 = (f>=par.normalize_range(1)) & (f<=par.normalize_range(2));
      % trim out potential line noise frequencies
      bw = 2.5;
      lf = [50 100 150 200];
      for j = 1:numel(lf)
         ind2 = ind2 & ((f<=(lf(j)-bw)) | (f>=(lf(j)+bw)));
      end
      meanP = bsxfun(@rdivide,meanP,mean(meanP(ind2,:)));
   end

   [peakLoc,peakMag,peakDetected,truepeak,bandmax,bandavg] = psdpeak(10*log10(meanP),f,band_beta);
   out(1).peakLoc = peakLoc;
   out(1).peakMag = peakMag;
   out(1).peakDetected = peakDetected;
   out(1).truePeak = truepeak;
   out(1).bandmax = bandmax;
   out(1).bandavg = bandavg;
   out(1).power = 10*log10(meanP);
   out(1).f = f;
   maxtrue = and(out(1).bandmax,out(1).truePeak);
   if any(maxtrue)
      win = [out(1).peakLoc(maxtrue)-5 out(1).peakLoc(maxtrue)+5];
      ind = (f>=win(1)) & (f<=win(2));
      out(1).offavg = mean(10*log10(meanP(ind,:)));
   else
      out(1).offavg = nan(1,3);
   end
 

   ind = ismember(labels,{'01D' '12D' '23D'});
   meanP = nanmean(P(:,ind,:),3);
   if par.normalize
      ind2 = (f>=par.normalize_range(1)) & (f<=par.normalize_range(2));
      % trim out potential line noise frequencies
      bw = 2.5;
      lf = [50 100 150 200];
      for j = 1:numel(lf)
         ind2 = ind2 & ((f<=(lf(j)-bw)) | (f>=(lf(j)+bw)));
      end
      meanP = bsxfun(@rdivide,meanP,mean(meanP(ind2,:)));
   end

   [peakLoc,peakMag,peakDetected,truepeak,bandmax,bandavg] = psdpeak(10*log10(meanP),f,band_beta);
   out(2).peakLoc = peakLoc;
   out(2).peakMag = peakMag;
   out(2).peakDetected = peakDetected;
   out(2).truePeak = truepeak;
   out(2).bandmax = bandmax;
   out(2).bandavg = bandavg;
   out(2).power = 10*log10(meanP);
   out(2).f = f;
   maxtrue = and(out(2).bandmax,out(2).truePeak);
   if any(maxtrue)
      win = [out(2).peakLoc(maxtrue)-5 out(2).peakLoc(maxtrue)+5];
      ind = (f>=win(1)) & (f<=win(2));
      out(2).offavg = mean(10*log10(meanP(ind,:)));
   else
      out(2).offavg = nan(1,3);
   end
   
   % collect clinical data
end
