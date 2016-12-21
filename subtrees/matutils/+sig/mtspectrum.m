% MTSPECTRUM - Estimate multitaper power spectral density
%
%     [output,params] = mtspectrum(x,varargin)
%
%     Power spectral density estimates using Thomson's multitaper method.
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% INPUTS
%     x       - [samples x channels] matrix or cell array of such matrices
%               Required input, must be real
%               If cell array, number of channels must match. Use this
%               option to produce a single PSD for multiple data sections.
% OPTIONAL
%     hbw     - scalar (Hz), optional, default = thbw/T
%               Half-bandwidth, spectral concentration [-hbw hbw]
%     thbw    - scalar (Hz), optional, default = 4
%               Time-half-bandwidth product. If hbw is set, this will be
%               determined automatically.
%     f       - fmin:df:fmax, optional, default = linspace(0,nyquist,100)
%               Vector of frequencies for calculating PSD
%     Fs      - scalar sampling frequency, optional, default = 2pi
%     nfft    - scalar, optional
%               Determines the size of FFT. If f is defined, nfft =
%               numel(f), otherwise nfft = 2^nextpow2(length(x))
%     V       - nsamples x k matrix, optional
%               Matrix of tapers (eg., from dpss). If given, lambda must
%               also be supplied
%     lambda  - k x 1, optional
%               Eigenvalues of tapers V. If given, V must also be supplied.
%     k       - scalar, optional, default = 2*thbw - 1
%               # of tapers to average. There are less than 2*thbw-1 tapers 
%               with good concentration in the band [-hbw hbw]. Frequently,
%               people use 2*thbw-1, although this is an upper bound, 
%               in some cases K should be << 2*thbw-1.
%     weights - string, optional, default = 'adapt'
%               Algorithm for combining tapered estimates:
%               'adapt'  - Thomson's adaptive non-linear combination 
%               'unity'  - linear combination with unity weights
%               'eigen'  - linear combination with eigenvalue weights
%     quadratic - boolean, optional, default = false
%               True will reduce the local bias of the multitaper PSD using
%               the method outlined in Prieto et al. (2007)
%     dropLastTaper - boolean, optional, default = true
%               When V, lambda not supplied, 2*thbw tapers are calculated.
%               True drops the last, which is usually less concentrated.
%     robust  - string, optional, default = 'mean'
%               This applies only when x is a cell array, in which case it 
%               specifies how the estimates should be combined:
%               'mean'     - simple arithmetic mean, NaN's excluded
%               'median'   - median, NaN's excluded
%               'huber'    - robust location using Huber weights
%               'logistic' - robust location using logistic weights
%               'none'     - does not perform any averaging, returning
%                            section estimates [nf x nSections x nChannels]
%     Ftest   - boolean, optional, default = true
%               Thomson's harmonic F-test is applied to all frequencies in f
%     alpha   - scalar in [0,1], optional, default = []
%               When set, causes (1-alpha)% confidence intervals to be
%               estimated using confMethod (eg., if 95% conf intervals are
%               desired, alpha = 0.05).
%     confMethod - string, optional, default = 'asymp'
%               'asymp' - asymptotic confidence intervals
%               'jack'  - Jackknifed confidence intervals
%
% OUTPUTS
%     output  - Structure that always contains the fields:
%                f - frequencies
%                P - PSDs
%               May contain the following depending on input parameters
%                Fval - F-values associated with Thomson's harmonic F-test
%                v1   - dof for Thomson's harmonic F-test
%                v2   - dof for Thomson's harmonic F-test
%                pval - p-values associated with Thomson's harmonic F-test
%                CI - confidence intervals
%                dP - first derivative of spectrum (for quadratic = true)
%                ddP - second derivative of spectrum (for quadratic = true)
%     params  - Structure containing parameters
%
% REFERENCES
%     Percival DB & Walden AT (1993). Spectral Analysis for Physical
%       Applications. Cambridge University Press.
%     Prieto GA et al (2007). Reducing the bias of multitaper spectrum
%       estimates. Geophys J Int 171: 1269-1281.
%     Thomson DJ (1982). Spectrum estimation and harmonic analysis. Proc of
%       the IEEE 70: 1055-1096.
%     Thomson DJ (2007). Jackknifing multitaper spectrum estimates. IEEE
%       Sig Proc Mag 24: 20-30.
%
% EXAMPLES
%     Fs = 1024; dt = 1/Fs; t = (0:5207)'*dt;
%     x = .2*cos(2*pi*250*t) + .2*cos(2*pi*50*t) + 1*randn(size(t));
%     figure; subplot(311);
%     plot(t,x); axis tight; box off;
%     ylabel('Amplitude'); xlabel('time');
%     % MT spectrum with half-bandwidth of 0.5 Hz
%     [out,params] = sig.mtspectrum(x,'hbw',0.5,'Fs',Fs,'Ftest',true);
%     subplot(312);
%     plot(out.f,10*log10(out.P)); axis tight; box off;
%     ylabel('Power'); xlabel('frequency');
%     subplot(313);
%     ax = plotyy(out.f,out.Fval,out.f,log10(out.pval));
%     ax(1).YLabel.String = 'F-statistic';
%     ax(1).XLim = [0 max(out.f)];
%     ax(2).YLabel.String = 'log10 p-value';
%     ax(2).XLim = [0 max(out.f)];
%     % The effective time-half-bandwidth product for this signal length is
%     params.thbw
%
%     % Compare to Prieto et al's method for local bias reduction
%     clf; plot(out.f,10*log10(out.P));
%     [out,params] = sig.mtspectrum(x,'hbw',0.5,'Fs',Fs,'quadratic',true);
%     hold on;
%     % Zoom on the peaks to see the differences
%     plot(out.f,10*log10(out.P));
%
%     % Prieto's method also produces estimates of the PSD derivatives
%     figure; subplot(211);
%     plot(out.f,out.dP);
%     subplot(212); plot(out.f,out.ddP);
%
% SEE ALSO
%     sig.mtspectrum

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process

% TODO
% o confidence intervals
% x for section-averaging, avoid recalculating tapers if possible
% o multi-section F-test
function [output,params] = mtspectrum(x,varargin)

p = inputParser;
p.KeepUnmatched = true;
p.FunctionName = 'sig.mtspectrum';
p.addRequired('x');
p.addParameter('thbw',[],@(x) isscalar(x));
p.addParameter('hbw',[],@(x) isscalar(x));
p.addParameter('k',[],@(x) isnumeric(x));
p.addParameter('Fs',2*pi,@(x) isscalar(x));
p.addParameter('f',[],@(x) isnumeric(x));
p.addParameter('nfft',[],@(x) isnumeric(x));
p.addParameter('V',[],@(x) ismatrix(x));
p.addParameter('Ftest',false,@(x) islogical(x) || isscalar(x));
p.addParameter('alpha',[],@(x) isnumeric(x));
p.addParameter('confMethod','asymp',@ischar);
p.addParameter('lambda',[],@(x) isnumeric(x));
p.addParameter('lambdaThresh',0.9,@(x) isnumeric(x) && isscalar(x));
p.addParameter('weights','adapt',@(x) any(strcmp(x,{'adapt' 'eigen' 'unity'})));
p.addParameter('dropLastTaper',true,@(x) islogical(x) || isscalar(x));
p.addParameter('quadratic',false,@(x) islogical(x) || isscalar(x));
p.addParameter('robust','mean',@ischar);
p.addParameter('detrend','none');
p.addParameter('verbose',false,@(x) islogical(x) || isscalar(x));
p.parse(x,varargin{:});
par = p.Results;

checkInputs();

%% Cell array of signals, process each element holding adjusting tapers to
%% keep hbw the same
if iscell(x)
   nSections = numel(x);
   
   if nSections == 1
      par = rmfield(par,'x');
      [output,params] = sig.mtspectrum(x{1},par);
   else
      % Duration of each section
      Twin = cellfun(@(x) size(x,1)/par.Fs,par.x);
      
      params = par;
      temp = zeros(par.nf,par.Nchan,nSections);
      for i = 1:nSections
         % Adjust thbw & k to maintain desired hbw given the section length
         params.thbw(i) = Twin(i)*par.hbw;
         params.k(i) = max(2,min(round(2*params.thbw(i)),size(x{i},1)) - 1);
         % Form tapers if needed
         if (i==1) || (Twin(i)~=Twin(i-1))
            [V,lambda] = dpss(size(x{i},1),params.thbw(i),params.k(i));
         end
         par.thbw = params.thbw(i);
         par.k = params.k(i);
         par.V = V;
         par.lambda = lambda;
         try
            par = rmfield(par,'x');
         end
         [it,partemp] = sig.mtspectrum(x{i},par);
         params.dof{i} = partemp.dof;
         temp(:,:,i) = it.P;
      end
      
      % Section-average
      temp = permute(temp,[1 3 2]);
      if strcmp(params.robust,'none')
         p = temp;
      else
         p = zeros(par.nf,par.Nchan);
         for i = 1:par.Nchan
            %TODO: should issue warning on NaNs?
            switch lower(params.robust)
               case {'median'}
                  p(:,i) = median(temp(:,:,i),2);
               case {'huber'}
                  p(:,i) = stat.mlochuber(temp(:,:,i)','k',5)';
               case {'logistic'}
                  p(:,i) = stat.mloclogist(temp(:,:,i)','loc','nanmedian','k',5)';
               otherwise
                  p(:,i) = mean(temp(:,:,i),2);
            end
         end
      end
      
      params = rmfield(params,'x');
      output.f = it.f;
      output.P = p;
      % TODO HOW TO RETURN F-TEST IN THIS CASE?
   end
   return;
end

%% Start processing for individual sections
% Estimate two-sided spectrum
[S,Yk,dS,ddS,Fval,A,dof] = mtm_spectrum(par);

if isempty(par.f)
   nfft = par.nfft;
   w = psdfreqvec('npts',nfft,'Fs',par.Fs); % TODO replace dependency
   if rem(nfft,2) % ODD
      select = 1:(nfft+1)/2;
      S_unscaled = S(select,:); % Take only [0,pi] or [0,pi)
      S = [S_unscaled(1,:); 2*S_unscaled(2:end,:)];  % Only DC is a unique point and doesn't get doubled
   else  % EVEN
      select = 1:nfft/2+1;
      S_unscaled = S(select,:); % Take only [0,pi] or [0,pi)
      S = [S_unscaled(1,:); 2*S_unscaled(2:end-1,:); S_unscaled(end,:)]; % Don't double unique Nyquist point
   end
   f = w(select);
   if ~isempty(dS)
      dS = dS(select,:);
      ddS = ddS(select,:);
   end
else
   f = par.f;
end

% Scale by the sampling frequency to obtain the PSD [Power/freq]
Pxx = S./par.Fs;

output.f = f;
output.P = Pxx;
if exist('select','var')
   dof = dof(select,:);
end
par.dof = dof;

if ~isempty(par.alpha)   
   switch par.confMethod
      case 'asymp'
         % Asymptotic chi-squared 95% confidence interval, Percival and Walden p.255-6
         Ql = chi2inv(1 - par.alpha/2,dof);
         Qu = chi2inv(par.alpha/2,dof);
         CI = [dof.*Pxx./Ql , dof.*Pxx./Qu];
         % TODO, FORMATTING FOR MULTICHANNEL
      case 'jack'
         
   end
   
   output.CI = CI;
end
if ~isempty(dS)
   output.dP = dS;
   output.ddP = ddS;
end

if par.Ftest
   if exist('select','var')
      output.Fval = Fval(select,:);
   else
      output.Fval = Fval;
   end
   output.A = A;
   output.v1 = 2;
   output.v2 = 2*par.k - 2;
   output.pval = 1 - fcdf(output.Fval,output.v1,output.v2);
   %p=0.05/N
   %sig = finv(1-p,2,2*K-2); % F-distribution based 1-p% point
   

   f0 = [150 300];
   % Will have to match f0 to closest in grid
   
   for i = 1:par.Nchan
      for j = 1:numel(f0)
         % Frequency index around line element to remove
         ind = find((f>=(f0(j)-2*par.hbw)) & (f<=(f0(j)+2*par.hbw)));
         % Relative frequency for transformed tapers
         f2 = f(ind)-f0(j);
         
         % Fourier transform tapers on grid around line element
         fstart = f2(1);
         fstop = f2(end);
         nfft2 = length(f2);
         % Initial complex weight
         a = exp(2i*pi*fstart/par.Fs);
         % Relative complex weight
         w = exp(2i*pi*(fstart-fstop)/((nfft2-1)*par.Fs));
         H = czt(par.V,nfft2,w,a);
         
         % Subtract line component (currently uses unity weights!)
         A0 = A(f==f0(j),i);
         Pxx(ind,i) = mean( abs( Yk{i}(ind,:) - A0*H ).^2 ,2) ./ par.Fs;
      end
   end
   
   output.P_reshaped = Pxx;
end

if nargout == 2
   params = par;
   params = rmfield(params,'x');
end

%% Verify consistency of parameters (nested)
   function checkInputs()
      if iscell(par.x)
         N = sum(cellfun(@(x) size(x,1),par.x));
         T = sum(cellfun(@(x) size(x,1)/par.Fs,par.x));
         par.Nchan = unique(cellfun(@(x) size(x,2),par.x));
         assert(numel(par.Nchan)==1,'Multiple sections must have same number of channels');
      else
         [N,par.Nchan] = size(par.x);
         T = N/par.Fs;
         assert(isreal(par.x),'Signal must be real');
      end
      
      if isempty(par.V)
         if ~isempty(par.hbw)
            par.thbw = T*par.hbw;
         elseif ~isempty(par.thbw)
            par.hbw = par.thbw/T;
         else
            par.thbw = 4;
            par.hbw = par.thbw/T;
         end
         
         k = max(2,min(round(2*par.thbw),N));
         if isempty(par.k)
            par.k = k;
            if par.dropLastTaper
               par.k = par.k - 1;
            end
         else
            assert((par.k>=1) && (par.k<=k),...
               '# of tapers must be greater than 1 and < 2*nw-1');
         end
         if ~iscell(par.x)
            % Compute tapers, if cell wait for each section
            [par.V,par.lambda] = dpss(N,par.thbw,par.k);
         end
      elseif ~isempty(par.V) && isempty(par.lambda)
         error('Must provide lambda with V');
      elseif ~isempty(par.lambda) && isempty(par.V)
         error('Must provide V with lambda');
      else
         assert(size(par.V,2)==numel(par.lambda),'V does not match lambda');
         % If thbw was not passed in
         if isempty(par.thbw)
            par.tbhw = size(par.V,2)/2; % Assume coming from dpss
            par.hbw = par.thbw/T;
         end
         if isempty(par.k)
            par.k = numel(par.lambda);
         else
            par.k = min(numel(par.lambda),par.k);
         end
      end
      
      if ~any(strcmpi(par.detrend,{'none' 'constant' 'linear'}))
         error('detrend options are ''none'', ''constant'' or ''linear''.');
      end
      
      if ~iscell(par.x)
         % Do tapers pass the eigenvalue threshold?
         ind = find(par.lambda < par.lambdaThresh);
         if ~isempty(ind)
            if par.verbose
               fprintf(strcat('# of tapers reduced from %g to %g due to eigenvalues < %1.3f\n',...
                  'Decrease lambdaThresh if you do not want this behavior.\n'),...
                  par.k,par.k-numel(ind),par.lambdaThresh);
            end
            par.k = max(1,ind(1)-1);
         end
      end
      
      if isempty(par.f)
         if isempty(par.nfft)
            par.nfft = max(256,2^nextpow2(N));
         end
         
         assert(par.nfft >= N,'nfft must be greater than signal length');
         
         if rem(par.nfft,2)
            par.nf = (par.nfft+1)/2;
         else
            par.nf = par.nfft/2+1;
         end
      else
         par.f = par.f(:);
         assert(all(par.f >= 0),'No negative frequencies');
         [par.fstart,par.fstop,par.npts,maxerr] = getUniformApprox(par.f);
         assert(maxerr < 3*eps(class(par.f)),'Need uniform f');
         par.nfft = numel(par.f);
         par.nf = numel(par.f);
         
         assert(max(par.f) <= par.Fs/2,'Frequencies must be less than Nyquist');
      end
   end % END checkInputs()

end % END mtpsectrum

%% Estimate MTM spectrum
function [S,Yk,dS,ddS,Fval,A,dof] = mtm_spectrum(params)

   if any(strcmpi(params.detrend,{'constant' 'linear'}))
      x = detrend(params.x,params.detrend);
   else
      x = params.x;
   end
   nfft = params.nfft;
   V  = params.V;
   lambda  = params.lambda;
   Fs = params.Fs;

   N = size(x,1);
   Nchan = params.Nchan;
   k = length(lambda);
   dof = zeros(nfft,Nchan);

   if params.Ftest
      Fval = zeros(nfft,Nchan);
      A = zeros(nfft,Nchan);
      Yk = cell(1,Nchan);
   else
      Fval = [];
      A = [];
      Yk = {};
   end

   % Precompute quantities that only depend on tapers
   if params.quadratic
      % Interpolate transformed tapers to denser frequency grid in [-W W]
      nfft2 = 8*2^nextpow2(nfft);
      nxi = 79;
      W = params.thbw/N;
      dxi = (2.0*W)/(nxi-1);
      xi = (-W:dxi:W);
      if (mod(nfft2,2)==0)
         fsamp = (-nfft2/2:nfft2/2-1)'/(nfft2);
      else
         fsamp = (-(nfft2-1)/2:(nfft2-1)/2)'/(nfft2-1);
      end

      % Interpolated tapers in frequency-domain
      ind = (fsamp>=2*xi(1)) & (fsamp<=2*xi(end));
      Vk = fftshift(fft(V,nfft2),1);
      Vj = interp1(fsamp(ind),Vk(ind,:),xi,'pchip');
      Vj = bsxfun(@times,Vj,1./sqrt(lambda'));
      clear Vk;

      % Interpolated eigenspectra
      L = k*k;
      m = 0;
      Pk = zeros(L,numel(xi));
      for j = 1:k
         for k = 1:k
            m = m + 1;
            Pk(m,1:nxi) = conj(Vj(:,j)) .* (Vj(:,k));
         end
      end
      Pk(:,[1 nxi]) = 0.5*Pk(:,[1 nxi]);

      % Chebyshev polynomial as the expansion basis
      hk = [sum(Pk,2) , Pk*(xi/W)' , Pk*(2*((xi/W).^2) - 1)']*dxi;

      % Least squares solution
      [Q,R] = qr(hk);

      % Covariance estimate
      ri = R \ eye(L);
      covb = real(ri*ri');

      dS = zeros(nfft, Nchan);
      ddS = zeros(nfft, Nchan);
   else
      dS = [];
      ddS = [];
   end

   %% Loop over channels
   S = zeros(nfft, Nchan);
   for chan = 1:Nchan
      % Tapered signal
      xvk = bsxfun(@times,V(:,1:k),x(:,chan));

      % Fourier transform of tapered signal (eigencoefficients)
      if isempty(params.f)
         yk = fft(xvk,nfft);
      else
         % Compute at specified grid using chirp-z transform
         % Initial complex weight
         a = exp(2i*pi*params.fstart/Fs);
         % Relative complex weight
         w = exp(2i*pi*(params.fstart-params.fstop)/((params.npts-1)*Fs));
         yk = czt(xvk,params.npts,w,a);      
         %yk = spectralZoom(xvk,Fs,params.fstart,params.fstop,params.npts);
      end

      % Spectral estimate for each taper
      Sk = abs(yk).^2;

      if params.Ftest
         % Thomson's (1982) harmonic F-test (eq. 13.10)
         Uk0 = sum(V);
         Uk0sq = sum(Uk0.^2);
         ykUk0 = sum(bsxfun(@times,yk,Uk0),2);
         u = bsxfun(@rdivide,ykUk0,Uk0sq);
         ykhat = bsxfun(@times,u,Uk0);

         num = (k-1)*(abs(u).^2)*Uk0sq;
         den = sum( abs(yk-ykhat).^2 ,2);
         Fval(:,chan) = num./den;
         A(:,chan) = u; % Amplitudes
         
         Yk{chan} = yk;
      end

      % Combined tapered spectral estimates
      switch params.weights
         case 'adapt'
            if k > 1
               % The algorithm converges so fast that results are
               % usually 'indistinguishable' after about three iterations.
               % This version uses the equations from [2] (P&W pp 368-370).
               sig2 = x(:,chan)'*x(:,chan)/N;  % Power
               Schan = (Sk(:,1)+Sk(:,2))/2;    % Initial spectrum estimate
               S1 = zeros(nfft,1);

               % Set tolerance for acceptance of spectral estimate:
               tol = 0.0005*sig2/nfft;
               a = bsxfun(@times,sig2,(1-lambda));
               loop = 0;
               while sum(abs(Schan-S1)/nfft)>tol
                  % calculate weights
                  b = (Schan*ones(1,k))./(Schan*lambda'+ones(nfft,1)*a');
                  dk = (b.^2).*(ones(nfft,1)*lambda');
                  % calculate new spectral estimate
                  S1 = sum(dk'.*Sk')./ sum(dk,2)';
                  S1 = S1';
                  Stemp = S1; S1 = Schan; Schan = Stemp;  % swap S and S1
                  loop = loop + 1;
                  if loop > 100 % TODO, problem with convergence compared to PMTM?
                     break;
                  end
               end
               % Equivalent degrees of freedom, see p. 370 of Percival and Walden 1993.
               dof(:,chan) = ( 2*sum(bsxfun(@times,b.^2,lambda'),2).^2 ) ...
                             ./ sum(bsxfun(@times,b.^4,lambda'.^2),2);
               % DOF estimate from Thomson (eq. 5.5) can yield dof > 2k, due
               % to dk being greater than 1? Problem in algorithm convergence?
               %dof(:,chan) = 2*sum(dk,2);
            else
               Schan = Sk;
               dof(:,chan) = 2*ones(nfft,1);
            end
         case {'unity','eigen'}
            % Compute the averaged estimate: simple arithmetic averaging is used.
            % The Sk can also be weighted by the eigenvalues, as in Park et al.
            % Eqn. 9.; note that the eqn. apparently has a typo; as the weights
            % should be lambda and not 1/lambda.
            if strcmp(params.weights,'eigen')
               wt = lambda(:);    % Park estimate
            else
               wt = ones(k,1);
            end
            Schan = Sk*wt/k;
      end

      if ~params.quadratic
         S(:,chan) = Schan;
      else % TODO: ASSUMES ADAPTIVE WEIGHTS NOW
         % Local bias reduction using the method developed by Prieto et al. (2007).
         % Follows Prieto's implementation (http://www.mit.edu/~gprieto/software.html),
         % vectorizing whenever possible.
         xk = dk.*yk; % tapered signal weighted by final weights

         m = 0;
         C = zeros(L,nfft);
         for j = 1:k
            for k = 1:k
               m = m + 1;
               C(m,:) = ( conj(xk(:,j)) .* (xk(:,k)) );
            end
         end

         btilde = Q' * C;
         hmodel = R \ btilde;
         slope = -real(hmodel(2,:))' / W;
         quad = real(hmodel(3,:))' / W^2;
         sigma2 = sum(abs( C - hk*real(hmodel) ).^2) / (L-3);
         quad_var  = (sigma2'*covb(3,3)) / W^4;

         %  Eq. 33 and 34 of Prieto et. al. (2007)
         qicorr = (quad.^2) ./ (quad.^2 + quad_var);
         qicorr = qicorr .* (1/6).*(W^2).*quad;

         S(:,chan) = Schan - qicorr;
         dS(:,chan)  = slope;
         ddS(:,chan) = quad;
      end
   end
end

% Ref: Martin GD (2005). Chirp Z-transform spectral zoom optimization
%      with Matlab. Sandia Report SAND 2005-7084.
% This is indeed slightly faster, but there are small differences between
% this and the standard czt call, that grow with signal length. I can't
% tell which is preferable for numerical stability...
function z = spectralZoom(h,fs,f1,f2,m)
[k, n] = size(h); oldk = k;
if k == 1, h = h(:); [k, n] = size(h); end

%------- Length for power-of-two fft
nfft = 2^nextpow2(k+m-1);

%------- Premultiply data
kk = ((-k+1):max(m-1,k-1)).';
kk2 = (kk.^2)./2;
wPow = times( -1i*2*pi*(f2-f1)/((m-1)*fs) , kk2 );
ww = exp(wPow);
nn = (0:(k-1))';
aPow = times( -1i*2*pi*f1/fs , nn );
aa = exp(aPow);
aa = aa.*ww(k+nn);
y = h.*aa(:,ones(1,n));

%------- Fast convolution via FFT
fy = fft(y,nfft);
fv = fft(1./ww(1:(m-1+k)),nfft);
fy = fy.*fv(:,ones(1, n));
z  = ifft(fy);

%------- Final multiply
z = z(k:(k+m-1),:) .* ww(k:(k+m-1),ones(1, n));

if oldk == 1, z = transpose(z); end
end