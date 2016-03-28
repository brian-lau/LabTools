% Power spectral density of univariate autoregressive process
% A     - coefficients
% sigma - noise standard deviation
% Fs    - sampling frequency
% f     - frequencies at which to evaluate spectrum
%
% Percival & Walden (1993). Spectral Analysis for Physical Applications.
%   Cambridge University Press. pg. 168
function psd = arspectrum(A,sigma,Fs,f)

if nargin < 4
   f = (0:(Fs/2))';
else
   f = f(:);
end

psd = zeros(size(f));
for i = 1:numel(A)
   psd = psd + A(i)*exp(-1j*2*pi*i*f/Fs);
end
psd = abs(1 - psd).^2;
psd = sigma^2/Fs./psd;