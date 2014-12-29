function plotwinpsd(varargin)

p = inputParser;
p.KeepUnmatched = true;
addParamValue(p,'basedir','/Volumes/Data/Human',@ischar);
addParamValue(p,'savedir',pwd,@ischar);
addParamValue(p,'area','STN',@ischar);
addParamValue(p,'patient','',@ischar);
addParamValue(p,'recording','Postop',@ischar);
addParamValue(p,'protocol','',@ischar);
addParamValue(p,'task','',@ischar);
addParamValue(p,'condition','',@ischar);
addParamValue(p,'run','',@isscalar);

% Saving
addParamValue(p,'overwrite',false,@islogical);

parse(p,varargin{:});
p = p.Results;

info = filterFilename(fullfile(p.basedir,p.area,p.patient,p.recording));
info = filterFilename(info,'protocol',p.protocol,'task',...
   p.task,'condition',p.condition,'run',p.run);

for i = 1:numel(info)
   info(i).path = p.savedir;
   info(i).filetype = '.mat';
   info(i).run = 'WINPSD';
end

fnames = unique(buildFilename(info));

if numel(fnames) > 2
   error('too many');
end

figure;
for i = 1:numel(fnames)
   load(fnames{i});

   P2 = P;
   for j = 1:numel(f)
      P2(j,:,:) = squeeze(P(j,:,:)).*(1-reject');
   end
   P = P2;
   %P(:,:,reject==1) = NaN;
   
   ind = ismember(labels,{'01G' '12G' '23G'});
   meanP = nanmean(P(:,ind,:),3);
   if numel(findstr(fnames{i},'_OFF_'))
      subplot(3,2,1); hold on
      title('OFF');
      meanOffG = meanP;
   else
      subplot(3,2,3); hold on
      title('ON');
      meanOnG = meanP;
   end
   plot(f,10*log10(meanP));
   axis([0 100 -25 5]);
   legend({'01G' '12G' '23G'});
   
   ind = ismember(labels,{'01D' '12D' '23D'});
   meanP = nanmean(P(:,ind,:),3);
   if numel(findstr(fnames{i},'_OFF_'))
      subplot(3,2,2); hold on
      title('OFF');
      meanOffD = meanP;
   else
      subplot(3,2,4); hold on
      title('ON');
      meanOnD = meanP;
   end
   plot(f,10*log10(meanP));
   axis([0 100 -25 5]);
   legend({'01D' '12D' '23D'});
end

if exist('meanOnG','var') && exist('meanOffG','var')
   subplot(3,2,5); hold on
   plot([0 100],[0 0],'k--');
   plot([4 4],[-10 10],'k:'); text(4,10.5,'4','HorizontalAlignment','center');
   plot([8 8],[-10 10],'k:'); text(8,10.5,'8','HorizontalAlignment','center');
   plot([13 13],[-10 10],'k:'); text(13,10.5,'13','HorizontalAlignment','center');
   plot(f,10*log10(meanOnG./meanOffG));
   title('10*log10(ON/OFF)');
   axis([0 100 -10 10]);
   
   subplot(3,2,6); hold on
   plot([0 100],[0 0],'k--'); text(4,10.5,'4','HorizontalAlignment','center');
   plot([4 4],[-10 10],'k:'); text(8,10.5,'8','HorizontalAlignment','center');
   plot([8 8],[-10 10],'k:'); text(13,10.5,'13','HorizontalAlignment','center');
   plot([13 13],[-10 10],'k:');
   plot(f,10*log10(meanOnD./meanOffD));
   title('10*log10(ON/OFF)');
   axis([0 100 -10 10]);
end
%suptitle([patient ' - ' type ' - norm=' num2str(normFlag)])

