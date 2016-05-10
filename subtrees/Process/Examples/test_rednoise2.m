% TODO: test with other background shapes

clear all
rng(23351);
Fs = 2000;
T = 30;
step = 5;
p = [0.01 0.05 0.1];
N = 100;

for i = 1:N
   i
   s1 = fakeLFP2(Fs,T,4);
   %s2 = fakeLFP2(Fs,T,6);

   S = Spectrum('input',s1,'step',step);
   S.rawParams = struct('f',0:.25:500,'hbw',1,'detrend','linear');
   S.baseParams = struct('method','broken-power','smoother','none');
   
   S.run;
   
   psdRaw{i} = S.raw.values{1};
   psdWhite{i} = S.detail.values{1};
   for j = 1:numel(p)
      [~,fa{i,j}] = S.threshold(p(j));
   end
end

f = S.raw.f;
nbins = 150;

figure;
subplot(421); hold on
psdall = cat(1,psdRaw{:});
plot(f,mean(psdall));
set(gca,'yscale','log');

subplot(422); hold on
psdall = cat(1,psdWhite{:});
plot(f,mean(psdall));
grid on;

edp = linspace(0,.15,nbins);
edf = linspace(0,f(end),nbins);
bwf = mean(diff(edf));
num = cellfun(@(x) numel(x),fa) ./ numel(f);

i = 1;
subplot(4,2,3); hold on
histogram(num(:,i),edp,'Normalization','count');
plot([p(i) p(i)],get(gca,'ylim'),'--');

subplot(4,2,4); hold on
h = histogram(cat(2,fa{:,i}),edf,'Normalization','count');
y = p(i)*numel(S.rawParams.f)*N/h.NumBins;
plot(get(gca,'xlim'),[y y],'--');
plot(get(gca,'xlim'),[mean(h.Values) mean(h.Values)],'-');

i = 2;
subplot(4,2,5); hold on
histogram(num(:,i),edp,'Normalization','count');
plot([p(i) p(i)],get(gca,'ylim'),'--');

subplot(4,2,6); hold on
h = histogram(cat(2,fa{:,i}),edf,'Normalization','count');
y = p(i)*numel(S.rawParams.f)*N/h.NumBins;
plot(get(gca,'xlim'),[y y],'--');
plot(get(gca,'xlim'),[mean(h.Values) mean(h.Values)],'-');

i = 3;
subplot(4,2,7); hold on
histogram(num(:,i),edp,'Normalization','count');
plot([p(i) p(i)],get(gca,'ylim'),'--');

subplot(4,2,8); hold on
h = histogram(cat(2,fa{:,i}),edf,'Normalization','count');
y = p(i)*numel(S.rawParams.f)*N/h.NumBins;
plot(get(gca,'xlim'),[y y],'--');
plot(get(gca,'xlim'),[mean(h.Values) mean(h.Values)],'-');
