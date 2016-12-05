% % Adaptive according to phase-frequency
% [hp,ha] = sig.designFilterBankPAC(4:2:40,50:4:200,1000);
% 
% % van Wijk et al, 2016
% [hp,ha] = sig.designFilterBankPAC(5:.5:35,150:2:400,1000,'type','uniform','bwp',1,'bwa',70);
% % Hemptinne et al, 2013
% [hp,ha] = sig.designFilterBankPAC(4:2:50,10:4:400,1000,'type','eeglab_fir1');
% % Hemptinne et al, 2015
% [hp,ha] = sig.designFilterBankPAC(4:2:50,50:4:200,1000,'type','eeglab_fir1');
% % Ozkurt and Schnitzler, 2011
% [hp,ha] = sig.designFilterBankPAC(3:2:41,45:10:125,1000,'type','eeglab_firls');
function [hp,ha] = designFilterBankPAC(fp,fa,Fs,varargin)
p = inputParser;
p.KeepUnmatched = true;
p.addRequired('fp',@isnumeric)
p.addRequired('fa',@isnumeric)
p.addRequired('Fs',@(x) isnumeric(x) && isscalar(x))
p.addParameter('type','adapt',@ischar);
p.addParameter('bwp',4,@(x) isnumeric(x) && isscalar(x));
p.addParameter('bwa',35,@(x) isnumeric(x) && isscalar(x));
p.addParameter('tp',0.25,@(x) isnumeric(x) && isscalar(x));
p.addParameter('ta',0.25,@(x) isnumeric(x) && isscalar(x));
p.parse(fp,fa,Fs,varargin{:});
par = p.Results;

fp = fp(:)';
fa = fa(:);

switch par.type
   case {'eeglab_fir1'}
      [hp,ha] = eeglab_fir1(fp,fa,Fs);
   case {'eeglab_firls'}
      [hp,ha] = eeglab_firls(fp,fa,Fs);
   case {'uniform'}
      % Modulation filters
      Fp1 = fp - par.bwp/2;
      Fp2 = fp + par.bwp/2;
      bw = Fp2 - Fp1;
      Fst1 = Fp1 - bw*par.tp;
      Fst2 = Fp2 + bw*par.tp;
      
      for i = 1:numel(fp)
         hp(i) = kaiserbandpass(Fst1(i),Fp1(i),Fp2(i),Fst2(i),Fs);
      end
      
      % Carrier filters
      Fp1 = fa - par.bwa/2;
      Fp2 = fa + par.bwa/2;
      bw = Fp2 - Fp1;
      Fst1 = Fp1 - bw*par.ta;
      Fst2 = Fp2 + bw*par.ta;

      for i = 1:numel(fa) % rows changing amplitude
         ha(i) = kaiserbandpass(Fst1(i),Fp1(i),Fp2(i),Fst2(i),Fs);
      end
   case {'adapt'}
      % Modulation filters
      Fp1 = fp - par.bwp/2;
      Fp2 = fp + par.bwp/2;
      bw = Fp2 - Fp1;
      Fst1 = Fp1 - bw*par.tp;
      Fst2 = Fp2 + bw*par.tp;
      
      for i = 1:numel(fp)
         hp(i) = kaiserbandpass(Fst1(i),Fp1(i),Fp2(i),Fst2(i),Fs);
      end
      
      % Carrier filters (par.bwa ignored)
      Fp1 = bsxfun(@minus,fa,fp);
      Fp2 = bsxfun(@plus,fa,fp);
      bw = Fp2 - Fp1;
      Fst1 = max(0.1,Fp1 - bw*par.ta);
      Fst2 = Fp2 + bw*par.ta;

      for i = 1:numel(fa) % rows changing amplitude
         for j = 1:numel(fp) % columns changing phase
            ha(i,j) = kaiserbandpass(Fst1(i,j),Fp1(i,j),Fp2(i,j),Fst2(i,j),Fs);
         end
      end
   otherwise
      error('Unknown filterBankPAC type');
end

%% Kaiser-window FIR filter, force even order
function hh = kaiserbandpass(Fst1,Fp1,Fp2,Fst2,Fs)
fcuts = [Fst1 Fp1 Fp2 Fst2];
mags = [0 1 0];
devs = [0.005 0.001 0.005];

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
locutoff = fp - 1;
hicutoff = fp + 1;

for i = 1:numel(locutoff)
   filtorder = max(minfac*fix(srate/locutoff(i)),min_filtorder);
   filtorder = filtorder + rem(filtorder,2); % Force even order (not original default)
   filtwts = fir1(filtorder, [locutoff(i), hicutoff(i)]./(srate/2));
   hp(i) = dfilt.dffir(conv(filtwts,filtwts));
end

% Carrier filters
locutoff = fa - 2;
hicutoff = fa + 2;

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