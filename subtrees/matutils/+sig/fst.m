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
%     x     - 1xN vector, required
%     Fs    - scalar, optional, sampling frequency
%     fpass - [1x2], optional, default = [0 nyquist]
%             Limits for calculating S-transform
%     gamma - scalar, 1x2 or 1x3 vector, optional, default = 1
%             Parameters controlling the scaling of Gaussian window.
%             scalar  - sigma = gamma/f, # of cycles within 1 stdev
%             [a b]   - sigma = (a*f + b)/f
%             [a b c] - sigma = (a*f^c + b)/f
%     decimate - scalar, optional, default = 1
%             Decimation factor for frequency sampling, eg, 4 picks every
%             fourth frequency sample within fpass
%
% OUTPUTS
%     S  - S-transform (freq x time)
%     f  - frequencies
%     t  - times
%
% REFERENCES
%     Assous S and Boashash B (2012). Evaluation of the modified S-transform 
%     for time-frequency synchrony analysis and source localization.
%     EURSIP Journal on Advances in Signal Processing.
%
%     Moukadem A, Abdeslam D and Dieterlen A (2014). Chapter 2 in
%     Time-Frequency Domain for Segmentation and Classification of
%     Non-Stationary Signals: The Stockwell transform Applied on Biosignals
%     and Electrical Signals.
%
%     Stockwell RG, Mansinha L, Lowe RP (1996). Localization of the complex
%     spectrum: The S transform. IEEE Trans on Sig Proc 44(4): 998-1001.
%
% EXAMPLE
%     t = 0:0.001:2;                   % 2 secs @ 1kHz sample rate
%     x1 = 0.01 + chirp(t,5,1,100,'q');% Start @ 5Hz, cross 100Hz at t=1sec
%     x2 = cos(2*pi*200*t); x2(t>.5) = 0;
%     x3 = cos(2*pi*350*t); x3((t<.25)|(t>1)) = 0;
%     x = x1 + x2 + x3;
%
%     [S,f] = sig.fst(x,'Fs',1000,'gamma',2);
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
p.addParameter('fpass',[],@(x) isnumeric(x));
p.addParameter('gamma',1,@(x) isnumeric(x));
p.addParameter('decimate',1,@(x) isnumeric(x));
p.parse(x,varargin{:});
par = p.Results;

[M,N] = size(x);
if M > 1
   error('fst:inputSize','Input must be a row vector');
end

N2 = fix(N/2);
j = 1;
if N2*2 == N
   j = 0;
end

% Frequencies (cycles/sample)
f = [0:N2 -N2+1-j:-1]/N;
% Frequencies (cycles/second)
ff = par.Fs*f;

if isempty(par.fpass)
   fpass = [max(min(ff),0) max(ff)];
else
   fpass = [min(par.fpass) max(par.fpass)];
end
ind = find((ff>=min(fpass)) & (ff<=max(fpass)));
if (par.decimate > 1) && (par.decimate < N2)
   dec = max(1,fix(par.decimate));
   ind = ind(1:dec:end);
end
ff = ff(ind);

S = zeros(numel(ind),N);

X = fft(x,N);

% Drop DC component, which is estimated below
if min(fpass) == 0
   ind(1) = [];
end

% Determine how we want to scale the Gaussian
% sigma = gamma/f, # of cycles within 1 standard deviation
if isscalar(par.gamma)
   gamma = par.gamma;
elseif numel(par.gamma) == 2
   % Assous & Boashash eq. 18
   gamma = par.gamma(1)*f + par.gamma(2);
   %gamma = (1/N)*f + 4*var(x);
elseif numel(par.gamma) == 3
   % Moukadem et al. eq. 2.41
   gamma = par.gamma(1)*f.^par.gamma(3) + par.gamma(2);
end

% Gaussian windows in frequency-domain
W = 2*(pi*bsxfun(@rdivide,f.*gamma,f(ind)'));
G = exp((-W.^2)/2);

if fpass(1) == 0
   dc = 1;
else
   dc = 0;
end
count = 1;
for i = ind
   Xs = circshift(X,[0,-(i-1)]);        % circshift the spectrum X
   S(count+dc,:) = ifft(Xs.*G(count,:));
   count = count + 1;
end

% DC component
if fpass(1) == 0
   S(1,:) = mean(x);
end

if nargout > 1
   f = ff;
end

if nargout == 3
   dt = 1/par.Fs;
   t = 0:dt:(dt*(N-1));
end

