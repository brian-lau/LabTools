% FST - Stockwell transform (S-transform) of signal
%
%     [S,f,t] = fst(x,varargin)
%
%     Time-frequency representation based on extention of continuous
%     wavelet transform using a moving Gaussian window that is scaled
%     according to frequency. 
%     
%     Core algorithm from Assous & Boashash.
%     
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% INPUTS
%     x     - MxN vector, required
%             M is assumed to represent channels
%             N is assumed to represent time
%     Fs    - scalar, optional, sampling frequency
%     fpass - [1x2], optional, default = [0 nyquist]
%             Limits for calculating S-transform
%     params - scalar, 1x2 or 1x3 vector, optional, default = 1
%             Parameters controlling the scaling of Gaussian window, the
%             # of cycles within 1 stdev
%             m         - sigma = m/f [STOCKWELL] 
%             r         - sigma = f^(1-p)/f [SEJDIC]
%             [m k]     - sigma = (m*f + k)/f
%             [m p k]   - sigma = (m*f^p + k)/f
%             [r m p k] - sigma = (m*f^p + k)/f^r
%     sejdic - boolean, optional, default = False
%             This toggles between the two possibilities for scalar
%             parameters
%     decimate - scalar, optional, default = 1
%             Decimation factor for frequency sampling, eg, 4 picks every
%             fourth frequency sample within fpass
%     pad   - integer >=0, optional, default = 0
%             Number of samples to pad the beginning and end of signal to
%             attenuate edge effects
%     padmode - string, optional, default = 'zpd'
%             One of below, only active if pad>0
%             'zpd' - pad with zeros
%             'sym' - pad by reflecting start and end of signal
%
% OUTPUTS
%     S  - S-transform (freq x time x #channels)
%     f  - frequencies
%     t  - times
%
% REFERENCES
%     Assous S and Boashash B (2012). Evaluation of the modified S-transform 
%     for time-frequency synchrony analysis and source localization.
%     EURSIP Journal on Advances in Signal Processing.
%
%     Moukadem A, Bouguila Z, Abdeslam D and Dieterlen A (2015). A new 
%     optimized  Stockwell transform applied on synthetic and real non-
%     stationary signals. Digital Signal Processing
%
%     Stockwell RG, Mansinha L, Lowe RP (1996). Localization of the complex
%     spectrum: The S transform. IEEE Trans on Sig Proc 44(4): 998-1001.
%
% EXAMPLE
%     t = 0.001:0.001:2;                   % 2 secs @ 1kHz sample rate
%     x1 = 0.1 + chirp(t,5,1,100,'q');% Start @ 5Hz, cross 100Hz at t=1sec
%     x2 = cos(2*pi*200*t); x2(t>.5) = 0;
%     x3 = cos(2*pi*350*t); x3((t<.25)|(t>1)) = 0;
%     x = x1 + x2 + x3;
%
%     [S,f] = sig.fst(x,'Fs',1000);
%  
%     figure; 
%     subplot(411); plot(t,x);
%     title('Signal'); xlabel('Time (sec)');
%     subplot(412); imagesc(t,f,abs(S)); set(gca,'ydir','normal');
%     title('Magnitude of S-transform');
%     xlabel('Time (sec)'); ylabel('Frequency (Hz)');
%     subplot(413); hold on;
%     fx = abs(fft(x)); fx2 = abs(sum(S,2))';
%     plot(f,fx(1:numel(f))); plot(f,fx2(1:numel(f)));
%     title('Spectrum'); xlabel('Frequency (Hz)');
%     % Marginal property
%     subplot(414); plot(f,fx(1:numel(f)) - fx2(1:numel(f)));
%     title('Sum(S) - fft(x)'); xlabel('Frequency (Hz)');

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/matutils
function [S,f,t] = fst(x,varargin)

p = inputParser;
p.KeepUnmatched = true;
p.FunctionName = 'S-transform';
p.addRequired('x',@(x) isnumeric(x));
p.addParameter('Fs',1,@(x) isnumeric(x));
p.addParameter('fres',[],@(x) isnumeric(x));
p.addParameter('fpass',[],@(x) isnumeric(x));
p.addParameter('params',[1 1 0 0],@(x) isnumeric(x));
p.addParameter('sejdic',false,@islogical);
p.addParameter('decimate',1,@(x) isnumeric(x));
p.addParameter('pad',0,@(x) isnumeric(x));
p.addParameter('padmode','zpd',@(x) any(strcmp(x,{'zpd' 'sym'})));
p.parse(x,varargin{:});
par = p.Results;

[M,Nt] = size(x);
if par.pad
   switch par.padmode
      case {'zpd'}
         x = [zeros(M,par.pad) , x , zeros(M,par.pad)];
      case {'sym'}
         x = [x(:,par.pad+1:-1:2) , x , x(:,end-1:-1:end-par.pad)];
   end
   [~,N] = size(x);
else
   N = Nt;
end

% Set up parameter vector for Gaussian window
nParams = numel(par.params);
% r m p k
if nParams == 1
   if par.sejdic
      params = [par.params 0 1 1];
   else
      params = [1 par.params 0 0];
   end
elseif nParams == 2
   params = [1 par.params(1) 1 par.params(2)];
elseif nParams == 3
   params = [1 par.params(:)'];
elseif nParams == 4
   params = par.params;
end

nfft = N;
if isempty(nfft)
   nfft = 2^nextpow2(N);
   N = nfft;
end
X = fft(x,nfft,2);

N2 = fix(N/2);
j = 1;
if N2*2 == N
   j = 0;
end

f = [0:N2 -N2+1-j:-1]/N;
% Frequencies (cycles/second)
ff = par.Fs*f;

% Determine which frequencies to keep
if isempty(par.fpass)
   fpass = [max(min(ff),0) max(ff)];
else
   fpass = [min(par.fpass) max(par.fpass)];
end
ind = find((ff>=min(fpass)) & (ff<=max(fpass)));

if (par.decimate > 1) && (par.decimate < N2)
   dec = max(1,fix(par.decimate));
   ind = ind(1:dec:end);
elseif ~isempty(par.fres)
   dec = max(1,ceil(par.fres/(mean(diff(ff(ind))))));
   ind = ind(1:dec:end);
end

% Drop DC component, which is estimated below
if fpass(1) == 0
   ind(1) = [];
   dc = 1;
else
   dc = 0;
end

count = 1;
S = zeros(numel(ind),N,M);
for i = ind
   Xs = circshift(X,-(i-1),2);
   W = gwin(f,ff(i),params);
   for k = 1:M % for each channel
      S(count+dc,:,k) = ifft(Xs(k,:).*W,nfft,2);
   end
   count = count + 1;
end

if par.pad
   S = S(:,par.pad+1:end-par.pad,:);
end

% DC component
if fpass(1) == 0
   if M == 1
      S(1,:) = mean(x,2);
   else
      S(1,:,:) = repmat(mean(x,2)',Nt,1);
   end
   ind = [1,ind];
end

if nargout > 1
   f = ff(ind);
end

if nargout == 3
   dt = 1/par.Fs;
   t = 0:dt:(dt*(N-1));
end

% Fourier transformed Gaussian
% Parametrization from Moukadem et al. 2015 [r m p k]
% sigma = (m*f^p + k)/f^r
function [w,gamma] = gwin(t,f,params)
r = params(1); 
m = params(2);
p = params(3);
k = params(4);

gamma = m*f^(p-r+1) + k*f^(1-r);
w = (f/(gamma*sqrt(2*pi))) * exp((-f^2*t.^2)/(2*gamma^2));
w = w/sum(w);
w = fft(w);
