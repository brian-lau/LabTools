% waveforms [nT x nSpikes]
% Joshua M, Elias S, Levine O, Bergman H. Quantifying the isolation quality 
% of extracellularly recorded action potentials.
% J. Neurosci. Methods 2007; 163: 267?82.

% Stratton P, Cheung A, Wiles J, Kiyatkin E, Sah P, Windels F. Action potential 
% waveform variability limits multi-unit separation in freely behaving rats. 
% PLoS One 2012; 7: e38482.
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
   results(numel(uLabels)) = struct('p2p',[],'rms1',[],'rms2',[]);
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
      % Estimate noise as residuals
      noise = bsxfun(@minus,waveforms,meanwf);
   else
      noise = par.noise;
   end
   
   % Eq 7 Joshua et al.
   results.p2p =  p2p / (5*std(noise(:)));
   
   % from U. Rutishauser, E.M. Schuman, A.N. Mamelak 2006
   results.rms1 = norm(meanwf) /  sqrt(nT*var(noise(:)));
   
   % pg 3 Stratton et al.
   results.rms2 = rms(waveforms(:)) / rms(noise(:));
end