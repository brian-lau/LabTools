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

% normalization
addParamValue(p,'normalize',true,@islogical);
addParamValue(p,'normalize_range',[100 200],@isnumeric);

% plotting
addParamValue(p,'xlim',[1 250],@(x) isnumeric(x) && (numel(x)==2));
addParamValue(p,'ylim',[-30 5],@(x) isnumeric(x) && (numel(x)==2));
addParamValue(p,'xlog',false,@islogical);
addParamValue(p,'ylog',false,@islogical);

% Saving
addParamValue(p,'saveplot',true,@islogical);
addParamValue(p,'overwrite',false,@islogical);

parse(p,varargin{:});
par = p.Results;

info = filterFilename(par.basedir);
info = filterFilename(info,'patient',par.patient,'protocol',par.protocol,'task',...
   par.task,'condition',par.condition,'filetype','.mat','run','WINPSD');
if isempty(info)
   return;
end
fnames = unique(buildFilename(info));

if numel(fnames) > 2
   error('PLOTWINPSD works for <= two files');
end

h = figure;
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
      lf = [100 150 200];
      for j = 1:numel(lf)
         ind2 = ind2 & ((f<=(lf(j)-bw)) | (f>=(lf(j)+bw)));
      end
      meanP = bsxfun(@rdivide,meanP,mean(meanP(ind2,:)));
   end
   if numel(findstr(fnames{i},'_OFF_'))
      subplot(3,2,1); hold on
      title({sprintf('OFF-origFs=%g',origFs) sprintf('segments=%g ',sum(1-reject(:,ind))) sprintf('rejects=%g ',sum(reject(:,ind)))});
      meanOffG = meanP;
   else
      subplot(3,2,3); hold on
      title({sprintf('ON-origFs=%g',origFs) sprintf('segments=%g ',sum(1-reject(:,ind))) sprintf('rejects=%g ',sum(reject(:,ind)))});
      meanOnG = meanP;
   end
   plot(f,10*log10(meanP));
   axis([par.xlim par.ylim]);
   legend({'01G' '12G' '23G'});
   
   ind = ismember(labels,{'01D' '12D' '23D'});
   meanP = nanmean(P(:,ind,:),3);
   if par.normalize
      ind2 = (f>=par.normalize_range(1)) & (f<=par.normalize_range(2));
      % trim out potential line noise frequencies
      bw = 2.5;
      lf = [100 150 200];
      for j = 1:numel(lf)
         ind2 = ind2 & ((f<=(lf(j)-bw)) | (f>=(lf(j)+bw)));
      end
      meanP = bsxfun(@rdivide,meanP,mean(meanP(ind2,:)));
   end
   if numel(findstr(fnames{i},'_OFF_'))
      subplot(3,2,2); hold on
      title({sprintf('OFF-origFs=%g',origFs) sprintf('segments=%g ',sum(1-reject(:,ind))) sprintf('rejects=%g ',sum(reject(:,ind)))});
      meanOffD = meanP;
   else
      subplot(3,2,4); hold on
      title({sprintf('ON-origFs=%g',origFs) sprintf('segments=%g ',sum(1-reject(:,ind))) sprintf('rejects=%g ',sum(reject(:,ind)))});
      meanOnD = meanP;
   end
   plot(f,10*log10(meanP));
   axis([par.xlim par.ylim]);
   legend({'01D' '12D' '23D'});
end

if exist('meanOnG','var') && exist('meanOffG','var')
   subplot(3,2,5); hold on
   plot(par.xlim,[0 0],'k--');
   plot([4 4],[-10 5],'k:'); text(4,6,'4','HorizontalAlignment','center');
   plot([8 8],[-10 5],'k:'); text(8,6,'8','HorizontalAlignment','center');
   plot([13 13],[-10 5],'k:'); text(13,6,'13','HorizontalAlignment','center');
   plot([30 30],[-10 5],'k:'); text(30,6,'30','HorizontalAlignment','center');
   plot(f,10*log10(meanOnG./meanOffG));
   title('10*log10(ON/OFF)');
   axis([par.xlim -8 8]);
   set(gca,'xscale','log');
   
   subplot(3,2,6); hold on
   plot(par.xlim,[0 0],'k--');
   plot([4 4],[-10 5],'k:'); text(4,6,'4','HorizontalAlignment','center');
   plot([8 8],[-10 5],'k:'); text(8,6,'8','HorizontalAlignment','center');
   plot([13 13],[-10 5],'k:'); text(13,6,'13','HorizontalAlignment','center');
   plot([30 30],[-10 5],'k:'); text(30,6,'30','HorizontalAlignment','center');
   plot(f,10*log10(meanOnD./meanOffD));
   title('10*log10(ON/OFF)');
   axis([par.xlim -8 8]);
   set(gca,'xscale','log');
end
if par.normalize
   suptitle([par.patient ' - ' par.task '- Normalized [' num2str(par.normalize_range(1)) '-' num2str(par.normalize_range(2)) ']'])
else
   suptitle([par.patient ' - ' par.task])
end

if par.saveplot
   info(1).path = par.savedir;
   info(1).condition = '';
   info(1).run = 'WINPSD';
   info(1).filetype = '';
   savename = buildFilename(info(1));
   savename = savename{1}(1:end-1);
   orient tall;
   
   print(h,'-dpdf',savename);
   close;
else
   close;
end
