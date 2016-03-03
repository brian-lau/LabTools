% TFR - Transform SampledProcesses into time-frequency representations
%
%     obj = tfr(SampledProcess,varargin)
%     SampledProcess.tfr(varargin)
%
%     Currently returns the power spectral density.
%
%     When input is an array of Processes, will iterate and transform each.
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% INPUTS
%     method - string, optional, default = 'multitaper'
%              One of following indicating type of transformation
%              'multitaper' - Multitaper tfr using Chronux toolbox
%              'stft'       - Spectrogram using Signal Processing toolbox
%              'cwt'        - Continuous wavelet transform Wavelet toolbox
%              'stockwell'  - S-transform
%     f      - [fmin fmax], optional, default = [0 100]
%
%     tBlock - scalar, optional, default = 1 sec
%              Parameter is used by multitaper and stft methods only
%     tStep  - scalar, optional, default = 0.5 sec
%              Parameter is used by multitaper and stft methods only
%     
% OUTPUTS
%     obj    - SpectralProcess
%
% EXAMPLES
%     t = [0:0.001:2]';                    % 2 secs @ 1kHz sample rate
%     y1 = chirp(t,10,2,10,'q');
%     y2 = chirp(t,60,2,180,'q');
%     y3 = cos(2*pi*20*t); y3(t>.5) = 0;
%     y4 = cos(2*pi*100*t); y4((t<.25)|(t>1)) = 0;
% 
%     s = SampledProcess([y1*.25+y3+y4;y1+y2],'Fs',1000);
% 
%     tf(1) = tfr(s,'method','stft','tBlock',.5,'tStep',.05,'f',[0:200]);
%     tf(2) = tfr(s,'method','chronux','tBlock',.5,'tStep',.05,'f',[0:200],'tapers',[2 3]);
%     tf(3) = tfr(s,'method','cwt','f',[.1 200],'numVoices',32);
%     tf(4) = tfr(s,'method','stockwell','gamma',2,'f',[0.1 200],'decimate',3);
%     plot(tf,'log',false);

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process

% TODO
% multiple windows?
% link SampledProcess handle?
% type?
function obj = tfr(self,varargin)

p = inputParser;
p.KeepUnmatched= true;
p.FunctionName = 'SampledProcess tfr method';
p.addParameter('method','chronux',@(x) any(strcmp(x,...
   {'stft' 'spectrogram' 'chronux' 'multitaper' 'cwt' 'wavelet' 'stockwell' 'strans'})));
p.addParameter('tBlock',1,@(x) isnumeric(x) && isscalar(x));
p.addParameter('tStep',[],@(x) isnumeric(x) && isscalar(x));
p.addParameter('f',0:100,@(x) isnumeric(x) && isvector(x));
p.addParameter('type','psd',@ischar);
p.parse(varargin{:});
params = p.Unmatched;
par = p.Results;

nObj = numel(self);
obj(nObj,1) = SpectralProcess();
for i = 1:nObj
   obj(i) = tfrEach(self(i),par,params);
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
      params.Fs = obj.Fs;
      params.fpass = [min(par.f) max(par.f)];
      N = obj.dim{1}(1);
      N2 = fix(N/2);
      j = 1;
      if N2*2 == N
         j = 0;
      end
      f = [0:N2 -N2+1-j:-1]/N;
      ff = obj.Fs*f;
      fpass = [min(params.fpass) max(params.fpass)];
      ind = find((ff>=min(fpass)) & (ff<=max(fpass)));
      if isfield(params,'decimate')
         dec = max(1,fix(params.decimate));
         ind = ind(1:dec:end);
      end
      S = zeros(obj.dim{1}(1),numel(ind),n);
      for i = 1:n
         [temp,f] = sig.fst(obj.values{1}(:,i)',params);
         S(:,:,i) = abs(temp).^2';
      end
      tStep = obj.dt;
      tBlock = obj.dt;
   case {'wavelet', 'cwt'}
      % Currently required Wavelet toolbox
      % consider https://github.com/grinsted/wavelet-coherence
      
      if isempty(fn) || ~isfield(params,'wavelet')
         params.wavelet = 'bump';
      end
      
      switch params.wavelet % Defaults from cwtftinfo.m
         case {'morl' 'morlex' 'morl0'}
            params.f0 = 6/(2*pi);
         case 'bump'
            params.f0 = 5/(2*pi);
         otherwise
            error('SampledProcess:tfr:InputParam','Wavelet not supported');
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
         params.padmode = 'none';
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
   'params',params,...
   'labels',obj.labels,...
   'tStart',obj.tStart,...
   'tEnd',obj.tEnd,...
   'offset',obj.offset,...
   'window',obj.window...
   );
tfr.cumulOffset = obj.cumulOffset;

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


