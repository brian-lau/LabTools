% Fs = 1000;
% 
% fa = (4:4:40)
% fp = (50:10:250)'

function [hp,ha,fafp] = designFilterBankPAC(fp,fa,Fs,type)

if nargin < 4
   type = 'adapt';
end

fp = fp(:)';
fa = fa(:);

switch type
   case {'eeglab'}
   [hp,ha] = eeglab_fir1(fp,fa,Fs);
  
   case {'adapt'}
      % Modulation filters
      Fp1 = fp - 2;
      Fp2 = fp + 2;
      bw = Fp2 - Fp1;
      Fst1 = Fp1 - bw*.25;
      Fst2 = Fp2 + bw*.25;
      
      for i = 1:numel(fp)
         hp(i) = kaiserbandpass(Fst1(i),Fp1(i),Fp2(i),Fst2(i),Fs);
         %    dm(i) = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2',...
         %       Fst1(i),Fp1(i),Fp2(i),Fst2(i),60,.01,60,Fs);
         %    hm(i) = design(dm(i),'kaiserwin');
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
            fafp{i,j} = [num2str(fa(i)) '_' num2str(fp(j))];
            %       d(i,j) = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2',...
            %          Fst1(i,j),Fp1(i,j),Fp2(i,j),Fst2(i,j),60,.01,60,Fs);
            %       h(i,j) = design(d(i,j),'kaiserwin');
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
   filtwts = fir1(filtorder, [locutoff(i), hicutoff(i)]./(srate/2));
   hp(i) = dfilt.dffir(filtwts);
end

% Carrier filters
locutoff = fa - 4;
hicutoff = fa + 4;

for i = 1:numel(locutoff)
   filtorder = max(minfac*fix(srate/locutoff(i)),min_filtorder);
   filtwts = fir1(filtorder, [locutoff(i), hicutoff(i)]./(srate/2));
   ha(i) = dfilt.dffir(filtwts);
end