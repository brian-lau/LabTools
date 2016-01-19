% handle object array
% handle windows?

%method stft, chronux, wavelet, stockwell
%params
%link
% tBlock = 0.5;
% tStep= 0.1;
%f = 0:500;

function obj = toSpectralProcess(self,varargin)

if (nargin > 1) && isa(varargin{1},'inputParser')
   p = varargin{1};
else
   p = inputParser;
   p.KeepUnmatched= true;
   p.FunctionName = 'SpectralProcess toSpectrogram method';
   p.addParameter('method','chronux',@ischar);
   p.addParameter('tBlock',1,@(x) isnumeric(x) && isscalar(x));
   p.addParameter('tStep',0.5,@(x) isnumeric(x) && isscalar(x));
   p.addParameter('f',0:100,@(x) isnumeric(x) && isvector(x));
   p.parse(varargin{:});
   params = p.Unmatched;
end

par = p.Results;

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
      window = nBlock;
      noverlap = nBlock - nStep;
      n = numel(self.labels);
      for i = 1:n
         [temp,f,~] = spectrogram(self.values{1}(:,i),window,noverlap,par.f,self.Fs);
         S(:,:,i) = abs(temp');
      end
   case {'chronux' 'multitaper'}
      tfParams.tapers = [5 9];
      tfParams.pad = 0;
      tfParams.Fs = self.Fs;
      tfParams.fpass = par.f;
      [S,~,f] = mtspecgramc(self.values{1}, [tBlock tStep], tfParams);
   case {'stockwell', 'strans'}
   case {'wavelet', 'cwt'}
      f0 = 5/(2*pi);
      scales = helperCWTTimeFreqVector(max(.1,min(par.f)),max(par.f),f0,self.dt,32);
      
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
      error('bad method');
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

   % cumuloffset