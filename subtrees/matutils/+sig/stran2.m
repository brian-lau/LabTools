% http://asp.eurasipjournals.springeropen.com/articles/10.1186/1687-6180-2012-49#CR23
function [MST,f] = stran2(sig,Fs,fpass)

% Compute the MST

[M,N] = size(sig);                % get the length of the signal
if M > 1
   error('bad size');
end
N2 = fix(N/2);
j = 1;

if N2*2 == N
   j = 0;
end

f = [0:N2 -N2+1-j:-1]/N;       %frequency
if j
   MST = zeros(N2+1,N);          %allocate memory for positive frequencies of MST.
else
   MST = zeros(N2,N);          %allocate memory for positive frequencies of MST.
end
SIG = fft(sig,N);             %compute the signal spectrum

g = (1/N)*f + 4*var(sig);       %parameter gamma
%g = repmat(1,1,N);       %parameter gamma

for i = 2:N2
   SIGs = circshift(SIG,[0,-(i-1)]);     % circshift the spectrum SIG
   W = (g(i)/f(i))*2*pi*f;               % Scale Gaussian
   G = exp((-W.^2)/2);                   % W in Fourier domain
   MST(i,:) = ifft(SIGs.*G);             % Compute the complex values of MST
end

MST(1,:) = mean(sig);

if j
   f = Fs*f(1:N2+1);
else
   f = Fs*f(1:N2);
end

if nargin == 3
   ind = (f>=min(fpass))&(f<=max(fpass));
   f(~ind) = [];
   MST(~ind,:) = [];
end