% handle object array
% handle windows?

%method stft, chronux, wavelet, stockwell
%params
%link
% correct time vector?
% tBlock = 0.5;
% tStep= 0.1;
%f = 0:500;

function obj = tfr(self,varargin)

nObj = numel(self);
if nObj > 1
   for i = 1:nObj
      obj(i) = tfr(self(i),varargin{:});
   end
   return
end

if (nargin > 1) && isa(varargin{1},'inputParser')
   p = varargin{1};
else
   p = inputParser;
   p.KeepUnmatched= true;
   p.FunctionName = 'SampledProcess tfr method';
   p.addParameter('method','chronux',@ischar);
   p.addParameter('tBlock',1,@(x) isnumeric(x) && isscalar(x));
   p.addParameter('tStep',[],@(x) isnumeric(x) && isscalar(x));
   p.addParameter('f',0:100,@(x) isnumeric(x) && isvector(x));
   p.addParameter('tapers',[5 9],@(x) isnumeric(x) && isvector(x));
   p.addParameter('pad',0,@(x) isnumeric(x) && isscalar(x));
   p.parse(varargin{:});
   %params = p.Unmatched;
end
par = p.Results;

if isempty(par.tStep)
   par.tStep = par.tBlock/2;
end

% FIXME, handle simple power spectral density (tStep = 0)
% if tStep == 0
% ignore tBlock, and calculate in full window
% warn if tBlock does not equal window
% or perhaps use sigproc toolbox methods (pcov,pmtm,pwelch)
% maybe add chunk parameter for psd (averaging over chunks)

% Round to nearest sample
nBlock = max(1,floor(par.tBlock/self.dt));
nStep = max(0,floor(par.tStep/self.dt));
tBlock = nBlock*self.dt;
tStep = nStep*self.dt;

switch lower(par.method)
   case {'stft' 'spectrogram'}
      window = nBlock; % use Hanning window default
      noverlap = nBlock - nStep;
      n = numel(self.labels);
      for i = 1:n
         [temp,f,~] = spectrogram(self.values{1}(:,i),window,noverlap,par.f,self.Fs);
         S(:,:,i) = abs(temp');
      end
   case {'chronux' 'multitaper'}
      tfParams.tapers = par.tapers;
      tfParams.pad = par.pad;
      tfParams.Fs = self.Fs;
      tfParams.fpass = par.f;
      [S,~,f] = mtspecgramc(self.values{1}, [tBlock tStep], tfParams);
   case {'stockwell', 'strans'}
   case {'wavelet', 'cwt'}
      % Currently required Wavelet toolbox
      % consider https://github.com/grinsted/wavelet-coherence
      f0 = 5/(2*pi);
      scales = getScales(max(.1,min(par.f)),max(par.f),f0,self.dt,32);
      
      n = numel(self.labels);
      for i = 1:n
         wt = cwtft({self.values{1}(:,i),self.dt},'wavelet','bump','scales',scales);
         S(:,:,i) = fliplr(abs(wt.cfs').^2);
         tStep = self.dt;
         tBlock = self.dt;
      end
      % Orient frequencies as ascending sequence (power as well above)
      f = flipud(wt.frequencies(:));
   otherwise
      error('Bad method for tfr!');
end

obj = SpectralProcess(S,...
   'f',f,...
   'params',p,...
   'tBlock',tBlock,...
   'tStep',tStep,...
   'labels',self.labels,...
   'tStart',self.tStart,...
   'tEnd',self.tEnd,...
   'offset',self.offset,...
   'window',self.window...
   );
obj.cumulOffset = self.cumulOffset;

function scales = getScales(minfreq,maxfreq,f0,dt,NumVoices)
%   scales = helperCWTTimeFreqVector(minfreq,maxfreq,f0,dt,NumVoices)
%   minfreq = minimum frequency in cycles/unit time. minfreq must be
%   positive.
%   maxfreq = maximum frequency in cycles/unit time
%   f0 - center frequency of the wavelet in cycles/unit time
%   dt - sampling interval
%   NumVoices - number of voices per octave
%
%   This function helperCWTTimeFreqPlot is only in support of
%   CWTTimeFrequencyExample and PhysiologicSignalAnalysisExample. 
%   It may change in a future release.

a0 = 2^(1/NumVoices);
minscale = f0/(maxfreq*dt);
maxscale = f0/(minfreq*dt);
minscale = floor(NumVoices*log2(minscale));
maxscale = ceil(NumVoices*log2(maxscale));
scales = a0.^(minscale:maxscale).*dt;


