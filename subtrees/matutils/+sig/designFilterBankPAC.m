% Fs = 1000;
% 
% fa = (4:4:40)
% fp = (50:10:250)'
% uniform, bwp, bwa
%
% [hp1,ha1] = sig.designFilterBankPAC(3:2:41,45:10:125,1000,'eeglab_firls');
function [hp,ha] = designFilterBankPAC(fp,fa,Fs,type)
%          p = inputParser;
%          p.KeepUnmatched= false;
%          p.FunctionName = 'CFC constructor';
%          p.addParameter('input',[],@(x) isa(x,'SampledProcess'));
%          p.addParameter('fCentersPhase',(4:4:40),@(x) isnumeric(x));
%          p.addParameter('fCentersAmp',(150:10:350),@(x) isnumeric(x));
%          p.addParameter('filterBankType','adapt',@ischar);
%          p.addParameter('metric','mi',@ischar);
%          p.addParameter('nBoot',0,@(x) isnumeric(x) && isscalar(x));
%          p.addParameter('permAlgorithm','circshift',@ischar);
%          p.parse(varargin{:});
%          par = p.Results;

if nargin < 4
   type = 'adapt';
end

fp = fp(:)';
fa = fa(:);

switch type
   case {'eeglab_fir1'}
      [hp,ha] = eeglab_fir1(fp,fa,Fs);
   case {'eeglab_firls'}
      [hp,ha] = eeglab_firls(fp,fa,Fs);
   case {'uniform'}
      
   case {'adapt'}
      % Modulation filters
      Fp1 = fp - 2;
      Fp2 = fp + 2;
      bw = Fp2 - Fp1;
      Fst1 = Fp1 - bw*.25;
      Fst2 = Fp2 + bw*.25;
      
      for i = 1:numel(fp)
         hp(i) = kaiserbandpass(Fst1(i),Fp1(i),Fp2(i),Fst2(i),Fs);
      end
      
      % Carrier filters
      Fp1 = bsxfun(@minus,fa,fp);
      Fp2 = bsxfun(@plus,fa,fp);
      bw = Fp2 - Fp1;
      Fst1 = max(0.1,Fp1 - bw*.25);
      Fst2 = Fp2 + bw*.25;

      for i = 1:numel(fa)
         for j = 1:numel(fp)
            ha(i,j) = kaiserbandpass(Fst1(i,j),Fp1(i,j),Fp2(i,j),Fst2(i,j),Fs);
            %fafp{i,j} = [num2str(fa(i)) '_' num2str(fp(j))];
         end
      end
end

%% Kaiser-window FIR filter, force even order
function hh = kaiserbandpass(Fst1,Fp1,Fp2,Fst2,Fs)
fcuts = [Fst1 Fp1 Fp2 Fst2];
mags = [0 1 0];
devs = [0.01 0.001 0.01];

[n,Wn,beta,ftype] = kaiserord(fcuts,mags,devs,Fs);
n = n + rem(n,2);
hh = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
hh = dfilt.dffir(hh);

%% The below are just for testing. Note that in both cases, the authors used
%% EEGLAB, which uses two-pass filtering (filtfilt). To make this compatible 
%% with our tools, these filters are convolved with themselves to get the
%% correct order and ripple/attenuation so that we can get the same results
%% using filter (one-pass)

%% EEGLAB, default settings from Hemptinne et al
% Code from https://sccn.ucsd.edu/svn/software/eeglab/functions/sigprocfunc/eegfilt.m
function [hp,ha] = eeglab_fir1(fp,fa,Fs)
srate = Fs;
minfac         = 3;    % this many (lo)cutoff-freq cycles in filter
min_filtorder  = 15;   % minimum filter length

% Modulation filters
locutoff = fp - 2;
hicutoff = fp + 2;

for i = 1:numel(locutoff)
   filtorder = max(minfac*fix(srate/locutoff(i)),min_filtorder);
   filtorder = filtorder + rem(filtorder,2); % Force even order (not original default)
   filtwts = fir1(filtorder, [locutoff(i), hicutoff(i)]./(srate/2));
   hp(i) = dfilt.dffir(conv(filtwts,filtwts));
end

% Carrier filters
locutoff = fa - 4;
hicutoff = fa + 4;

for i = 1:numel(locutoff)
   filtorder = max(minfac*fix(srate/locutoff(i)),min_filtorder);
   filtorder = filtorder + rem(filtorder,2); % Force even order (not original default)
   filtwts = fir1(filtorder, [locutoff(i), hicutoff(i)]./(srate/2));
   ha(i) = dfilt.dffir(conv(filtwts,filtwts));
end

%% EEGLAB, default settings from Ozkurt and Schnitzler, 2011
% Code from https://sccn.ucsd.edu/svn/software/eeglab/functions/sigprocfunc/eegfilt.m
function [hp,ha] = eeglab_firls(fp,fa,Fs)
srate = Fs;
nyq            = srate*0.5;  % Nyquist frequency
minfac         = 3;    % this many (lo)cutoff-freq cycles in filter
min_filtorder  = 15;   % minimum filter length
MINFREQ = 0;
trans          = 0.15; % fractional width of transition zones

% Modulation filters
locutoff = fp - 1;
hicutoff = fp + 1;

for i = 1:numel(locutoff)
   filtorder = max(minfac*fix(srate/locutoff(i)),min_filtorder);
   filtorder = filtorder + rem(filtorder,2); % Force even order (not original default)
   f=[MINFREQ (1-trans)*locutoff(i)/nyq locutoff(i)/nyq hicutoff(i)/nyq (1+trans)*hicutoff(i)/nyq 1];
   m=[0       0                      1            1            0                      0];
   filtwts = firls(filtorder,f,m); % get FIR filter coefficients
   hp(i) = dfilt.dffir(conv(filtwts,filtwts));
end

% Carrier filters
locutoff = fa - 5;
hicutoff = fa + 5;

for i = 1:numel(locutoff)
   filtorder = max(minfac*fix(srate/locutoff(i)),min_filtorder);
   filtorder = filtorder + rem(filtorder,2); % Force even order (not original default)
   f=[MINFREQ (1-trans)*locutoff(i)/nyq locutoff(i)/nyq hicutoff(i)/nyq (1+trans)*hicutoff(i)/nyq 1];
   m=[0       0                      1            1            0                      0];
   filtwts = firls(filtorder,f,m); % get FIR filter coefficients
   ha(i) = dfilt.dffir(conv(filtwts,filtwts));
end