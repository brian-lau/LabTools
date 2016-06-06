% waveforms [nT x nSpikes]
function results = snr(waveforms,varargin)
p = inputParser;
p.KeepUnmatched = false;
p.addRequired('waveforms',@ismatrix);
p.addParameter('noise',[],@ismatrix);
p.addParameter('labels',[],@isvector);
p.parse(waveforms,varargin{:});
par = p.Results;

nT = size(waveforms,1);

if ~isempty(par.labels)
   uLabels = unique(par.labels);
   for i = 1:numel(uLabels)
      ind = par.labels == uLabels(i);
      results(i) = spk.snr(waveforms(:,ind),'noise',par.noise);
   end
   return;
else
   meanwf = mean(waveforms,2);
   
   %%
   p2p = max(meanwf) - min(meanwf);
   if isempty(par.noise)
      noise = bsxfun(@minus,waveforms,meanwf);
   else
      noise = par.noise;
   end
   
   % From Bergman paper
   results.p2p =  p2p / (5*std(noise(:)));
   
   % from U. Rutishauser, E.M. Schuman, A.N. Mamelak 2006
   results.rms1 = norm(meanwf) /  sqrt(nT*var(noise(:)));
   
   % http://www.plosone.org/article/info:doi/10.1371/journal.pone.0038482
   results.rms2 = rms(waveforms(:)) / rms(noise(:));
end