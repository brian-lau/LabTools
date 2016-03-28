% Generate noise with specified amplitude spectrum
% amp - [N x 1], required
%       Amplitude spectrum, including 0 (DC) and Fs/2 (Nyquist)
%
% y   - 2*N-2 vector of shaped noise
function y = noise(amp)

amp = amp(:);
N = numel(amp);
M = 2*N - 2; % except the DC component and Nyquist frequency - they are unique

x = randn(M,1);
X = fft(x);

% Shape positive frequencies
X(1:N) = X(1:N).*amp;

% Shape negative frequencies (process assumed real)
X(N+1:M) = real(X(M/2:-1:2)) -1i*imag(X(M/2:-1:2));

y = real(ifft(X));
