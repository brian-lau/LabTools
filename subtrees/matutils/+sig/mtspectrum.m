% MTSPECTRUM - Estimate multitaper power spectral density
%
%     [output,params] = mtspectrum(x,varargin)
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% INPUTS
%     x       - [samples x channels] matrix or cell array of such matrices
%               Required input, must be real
%               If cell array, number of channels must match
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
%     alpha   - scalar in [0,1], optional, default = 0.95
%               When set, causes confidence intervals to be returned
%     confMethod - string, optional, default = 'asymp'
%               'asymp' returns 
%
% OUTPUTS
%     output  - Structure that always contains the fields:
%               f - frequencies
%               P - PSDs
%               May contain the following depending on input parameters
%               CI - confidence intervals
%               dP - first derivative of spectrum
%               ddP - second derivative of spectrum
%     params  - Structure containing parameters
%
% REFERENCES
%     Percival DB & Walden AT (1993). Spectral Analysis for Physical
%       Applications. Cambridge University Press.
%     Prieto GA et al (2007). Reducing the bias of multitaper spectrum
%       estimates. Geophys J Int 171: 1269-1281.
%     Thompson DJ (2007). Jackknifing multitaper spectrum estimates. IEEE
%       Sig Proc Mag 24: 20-30.
%
% EXAMPLES
%
% SEE ALSO
%     sig.mtspectrum

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process

% TODO
% o confidence intervals
% o for section-averaging, avoid recalculating tapers if possible
function [output,params] = mtspectrum(x,varargin)

p = inputParser;
p.KeepUnmatched = true;
p.FunctionName = 'sig.pmtm';
p.addRequired('x');
p.addParameter('thbw',[],@(x) isscalar(x));
p.addParameter('hbw',[],@(x) isscalar(x));
p.addParameter('k',[],@(x) isnumeric(x));
p.addParameter('Fs',2*pi,@(x) isscalar(x));
p.addParameter('f',[],@(x) isnumeric(x));
p.addParameter('nfft',[],@(x) isnumeric(x));
p.addParameter('V',[],@(x) ismatrix(x));
p.addParameter('alpha',[],@(x) isnumeric(x));
p.addParameter('lambda',[],@(x) isnumeric(x));
p.addParameter('lambdaThresh',0.9,@(x) isnumeric(x) && isscalar(x));
p.addParameter('weights','adapt',@(x) any(strcmp(x,{'adapt' 'eigen' 'unity'})));
p.addParameter('dropLastTaper',true,@(x) islogical(x) || isscalar(x));
p.addParameter('quadratic',false,@(x) islogical(x) || isscalar(x));
p.addParameter('robust','huber',@ischar);
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
      Twin = cellfun(@(x) size(x,1)/par.Fs,par.x);
      
      params = par;
      temp = zeros(par.nf,par.Nchan,nSections);
      for i = 1:nSections
         % Adjust thbw & k to maintain desired hbw given the section length
         params.thbw(i) = Twin(i)*par.hbw;
         params.k(i) = max(2,min(round(2*params.thbw(i)),size(x{i},1)) - 1);
         [V,lambda] = dpss(size(x{i},1),params.thbw(i),params.k(i));
         par.thbw = params.thbw(i);
         par.k = params.k(i);
         par.V = V;
         par.lambda = lambda;
         try
            par = rmfield(par,'x');
         end
         it = sig.mtspectrum(x{i},par);
         temp(:,:,i) = it.P;
      end
      
      temp = permute(temp,[1 3 2]);
      
      p = zeros(par.nf,par.Nchan);
      for i = 1:par.Nchan
         %TODO: should issue warning on NaNs?
         switch lower(params.robust)
            case {'median'}
               p(:,i) = nanmedian(temp(:,:,i),2);
            case {'huber'}
               p(:,i) = stat.mlochuber(temp(:,:,i)','k',5)';
            case {'logistic'}
               p(:,i) = stat.mloclogist(temp(:,:,i)','loc','nanmedian','k',5)';
            otherwise
               p(:,i) = mean(temp(:,:,i),2);
         end
      end
      
      params = rmfield(params,'x');
      output.f = it.f;
      output.P = p;
   end
   return;
end

%% Start processing for individual sections
% Estimate two-sided spectrum
[S,dS,ddS] = mtm_spectrum(par);

if isempty(par.f)
   nfft = par.nfft;
   w = psdfreqvec('npts',nfft,'Fs',par.Fs); % TODO
   if rem(nfft,2),
      select = 1:(nfft+1)/2;  % ODD
      S_unscaled = S(select,:); % Take only [0,pi] or [0,pi)
      S = [S_unscaled(1,:); 2*S_unscaled(2:end,:)];  % Only DC is a unique point and doesn't get doubled
   else
      select = 1:nfft/2+1;    % EVEN
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
if ~isempty(par.alpha)
%    %Chi-squared 95% confidence interval
%    %approximation from Chamber's et al 1983; see Percival and Walden p.256, 1993
%    ci(:,1)=1./(1-2./(9*dof)-1.96*sqrt(2./(9*dof))).^3;
%    ci(:,2)=1./(1-2./(9*dof)+1.96*sqrt(2./(9*dof))).^3;
%   output.CI = CI;
end
if ~isempty(dS)
   output.dP = dS;
   output.ddP = ddS;
end

if nargout == 2
   params = par;
   params = rmfield(params,'x');
end

%% Verify consistency of parameters
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
      
      if ~iscell(par.x)
         % Do tapers pass the eigenvalue threshold?
         ind = find(par.lambda < par.lambdaThresh);
         if ~isempty(ind)
            fprintf(strcat('# of tapers reduced from %g to %g due to eigenvalues < %1.3f\n',...
               'Decrease lambdaThresh if you do not want this behavior.\n'),...
               par.k,par.k-numel(ind),par.lambdaThresh);
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
      end
   end % END checkInputs()

end % END pmtm

%%
% Local bias reduction using the method developed by Prieto et al. (2007).
% Follows Prieto's implementation (http://www.mit.edu/~gprieto/software.html),
% vectorizing whenever possible.
function [S,dS,ddS] = mtm_spectrum(params)
x = params.x;
nfft = params.nfft;
V  = params.V;
lambda  = params.lambda;
Fs = params.Fs;

N = size(x,1);
Nchan = size(x,2);
k = length(lambda);

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
end

%% Loop over channels
S = zeros(nfft, Nchan);
for chan=1:Nchan
   
   xin = bsxfun(@times,V(:,1:k),x(:,chan));
   % Compute the windowed DFTs
   if isempty(params.f)
      Xx = fft(xin,nfft);
   else
      % Ref: Martin GD (2005). Chirp Z-transform spectral zoom optimization
      %      with Matlab. Sandia Report SAND 2005-7084.
      % Above discusses some optimizations that may be worth implementing.
      % Initial complex weight
      a = exp(2i*pi*params.fstart/Fs);
      % Relative complex weight
      w = exp(2i*pi*(params.fstart-params.fstop)/((params.npts-1)*Fs));
      % Chirp-z transform
      Xx = czt(xin,params.npts,w,a);
   end
   
   Sk = abs(Xx).^2;
   
   % Compute the MTM spectral estimates, compute the whole spectrum 0:nfft.
   switch params.weights,
      case 'adapt'
         if k > 1
            % The algorithm converges so fast that results are
            % usually 'indistinguishable' after about three iterations.
            % This version uses the equations from [2] (P&W pp 368-370).
            sig2=x(:,chan)'*x(:,chan)/N;  % Power
            Schan=(Sk(:,1)+Sk(:,2))/2;    % Initial spectrum estimate
            S1=zeros(nfft,1);
            
            % Set tolerance for acceptance of spectral estimate:
            tol=.0005*sig2/nfft;
            a=bsxfun(@times,sig2,(1-lambda));
            while sum(abs(Schan-S1)/nfft)>tol
               % calculate weights
               b=(Schan*ones(1,k))./(Schan*lambda'+ones(nfft,1)*a');
               % calculate new spectral estimate
               wk=(b.^2).*(ones(nfft,1)*lambda');
               S1=sum(wk'.*Sk')./ sum(wk,2)';
               S1=S1';
               Stemp=S1; S1=Schan; Schan=Stemp;  % swap S and S1
            end
            % Equivalent degrees of freedom, see p. 370 of Percival and Walden 1993.
            %dof = (2*sum((b.^2).*(ones(nfft,1)*V'),2).^2) ./ sum((b.^4).*(ones(nfft,1)*V.^2'),2);
         else
            %TODO Single taper estimate
            %dof = 2*ones(nfft,1);
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
      dS = [];
      ddS = [];
   else % TODO: ASSUMES ADAPTIVE WEIGHTS NOW
      xk = wk.*Xx; % tapered signal weighted by final weights

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