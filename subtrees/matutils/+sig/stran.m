function ST=stran(h)
% Compute S-Transform without for loops

%%% Coded by Kalyan S. Dash %%%
%%% IIT Bhubaneswar, India %%%
% Copyright (c) 2015, Baba Dash
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.

[~,N]=size(h); % h is a 1xN one-dimensional series
nhaf=fix(N/2);

odvn=1;
if nhaf*2==N;
    odvn=0;
end

f=[0:nhaf -nhaf+1-odvn:-1]/N;
Hft=fft(h);

%Compute all frequency domain Gaussians as one matrix
invfk=[1./f(2:nhaf+1)]';
W=2*pi*repmat(f,nhaf,1).*repmat(invfk,1,N);
G=exp((-W.^2)/2); %Gaussian in freq domain
% End of frequency domain Gaussian computation

% Compute Toeplitz matrix with the shifted fft(h)
HW=toeplitz(Hft(1:nhaf+1)',Hft);

% Exclude the first row, corresponding to zero frequency
HW=[HW(2:nhaf+1,:)];

% Compute Stockwell Transform
ST=ifft(HW.*G,[],2); %Compute voice

%Add the zero freq row
st0=mean(h)*ones(1,N);

ST=[st0;ST];
end