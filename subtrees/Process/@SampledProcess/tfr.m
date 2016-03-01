% handle windows?

%method stft, chronux, wavelet, stockwell
%params
%link
% correct time vector?
% tBlock = 0.5;
% tStep= 0.1;
%f = 0:500;

function obj = tfr(self,varargin)

p = inputParser;
p.KeepUnmatched= true;
p.FunctionName = 'SampledProcess tfr method';
p.addParameter('method','chronux',@(x) any(strcmp(x,...
   {'stft' 'spectrogram' 'chronux' 'multitaper' 'cwt' 'wavelet' 'stockwell' 'strans'})));
p.addParameter('tBlock',1,@(x) isnumeric(x) && isscalar(x));
p.addParameter('tStep',[],@(x) isnumeric(x) && isscalar(x));
p.addParameter('f',0:100,@(x) isnumeric(x) && isvector(x));
p.parse(varargin{:});
params = p.Unmatched;
par = p.Results;

nObj = numel(self);
obj(nObj,1) = SpectralProcess();
for i = 1:nObj
   obj(i) = tfrEach(self(i),par,params);
   %obj(i).params = p;
end

%%
function tfr = tfrEach(obj,par,params)

if isempty(par.tStep)
   par.tStep = par.tBlock/2;
end

% Round to nearest sample
nBlock = max(1,floor(par.tBlock/obj.dt));
nStep = max(0,floor(par.tStep/obj.dt));
tBlock = nBlock*obj.dt;
tStep = nStep*obj.dt;

n = numel(obj.labels);
fn = fieldnames(params);

switch lower(par.method)
   case {'stft' 'spectrogram'}      
      window = nBlock; % Hamming window is used for each segment
      noverlap = nBlock - nStep;
      % Compute the number of segments
      M = obj.dim{1}(1);
      L = window;
      k = (M-noverlap)./(L-noverlap);
            
      S = zeros(floor(k),numel(par.f),n);
      for i = 1:n
         if ~isempty(fn) && isfield(params,'reassigned') && params.reassigned
            [~,f,~,temp] = spectrogram(obj.values{1}(:,i),window,noverlap,par.f,obj.Fs,'reassigned');
         else
            [~,f,~,temp] = spectrogram(obj.values{1}(:,i),window,noverlap,par.f,obj.Fs);
         end
         S(:,:,i) = abs(temp'); % abs unnecessary?
      end
   case {'chronux' 'multitaper'}
      if isempty(fn)
         params.tapers = [5 9];
         params.pad = 0;
      end
      params.Fs = obj.Fs;
      params.fpass = [min(par.f) max(par.f)];
      params.trialave = 0; % always False
      
      [S,~,f] = mtspecgramc(obj.values{1},[tBlock tStep],params);
   case {'stockwell', 'strans'}
      for i = 1:n
         [temp,f] = sig.stran2(obj.values{1}(:,i)',obj.Fs,par.f);
         S(:,:,i) = abs(temp)'; % abs unnecessary?
      end
      tStep = obj.dt;
      tBlock = obj.dt;
   case {'wavelet', 'cwt'}
      % Currently required Wavelet toolbox
      % consider https://github.com/grinsted/wavelet-coherence
      
      if isempty(fn)
         params.wavelet = 'bump';
      end
      
      switch params.wavelet % Defaults from cwtftinfo.m
         case {'morl' 'morlex' 'morl0'}
            params.f0 = 6/(2*pi);
         case 'bump'
            params.f0 = 5/(2*pi);
         otherwise
            error('Wavelet not supported');
      end
      
      if ~isfield(params,'numVoices')
         params.numVoices = 16;
      end
      
      % If scales passed in, ignore frequencies
      if ~isfield(params,'scales')
         % Min frequency forced to 0.01
         params.scales = getScales(max(0.01,min(par.f)),max(par.f),params.f0,obj.dt,params.numVoices);
      end
      
      if ~isfield(params,'padmode')
         params.padmode = 'zpd';
      end
      
      S = zeros(obj.dim{1}(1),numel(params.scales),n);
      for i = 1:n
         wt = cwtft({obj.values{1}(:,i),obj.dt},'wavelet',params.wavelet,...
            'scales',params.scales,'padmode',params.padmode);
         S(:,:,i) = fliplr(abs(wt.cfs').^2);
      end
      tStep = obj.dt;
      tBlock = obj.dt;
      % Orient frequencies as ascending sequence (power as well above)
      f = flipud(wt.frequencies(:));
end

tfr = SpectralProcess(S,...
   'f',f,...
   'tBlock',tBlock,...
   'tStep',tStep,...
   'labels',obj.labels,...
   'tStart',obj.tStart,...
   'tEnd',obj.tEnd,...
   'offset',obj.offset,...
   'window',obj.window...
   );
tfr.cumulOffset = obj.cumulOffset;
%    out = SampledProcess(values(:,ind2),...
%       'Fs',1/dt,...
%       'labels',uLabels(ind2),...
%       'tStart',relWindow(1),...
%       'tEnd',relWindow(2)...
%       );

% Utility for wavelet
function scales = getScales(minfreq,maxfreq,f0,dt,NumVoices)
%   scales = helperCWTTimeFreqVector(minfreq,maxfreq,f0,dt,NumVoices)
%   minfreq = minimum frequency in cycles/unit time. minfreq must be
%   positive.
%   maxfreq = maximum frequency in cycles/unit time
%   f0 - center frequency of the wavelet in cycles/unit time
%   dt - sampling interval
%   NumVoices - number of voices per octave

a0 = 2^(1/NumVoices);
minscale = f0/(maxfreq*dt);
maxscale = f0/(minfreq*dt);
minscale = floor(NumVoices*log2(minscale));
maxscale = ceil(NumVoices*log2(maxscale));
scales = a0.^(minscale:maxscale).*dt;


