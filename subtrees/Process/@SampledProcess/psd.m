% PSD - Estimate power spectral density of SampledProcess values
%
%     obj = psd(SampledProcess,varargin)
%     SampledProcess.psd(varargin)
%
%     When input is an array of Processes, will iterate and estimate each.
%     Multiple windows are only supported for the 'multitaper' method,
%     where a PSD is estimated for each window and combined according to
%     a location estimator that can be defined ('welch' windows internally).
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% INPUTS
%     method - string, optional, default = 'multitaper'
%              One of following indicating type of transformation
%              'multitaper' - Thompson's multitaper method
%              'welch'      - Welch's averaged, modified periodogram
%     f      - fmin:df:fmax, optional, default = linspace(0,nyquist,100)
%              Vector of frequencies for calculating PSD
%
% OPTIONAL
%     If method = 'multitaper'
%     hbw     - scalar (Hz), optional, default = thbw/T
%               Half-bandwidth, spectral concentration [-hbw hbw]
%     thbw    - scalar (Hz), optional, default = 4
%               Time-half-bandwidth product. If hbw is set, this will be
%               determined automatically.
%     K       - scalar, optional, default = 2*thbw - 1
%               # of tapers to average. There are less than 2*nw-1 tapers 
%               with good concentration in the band [-hbw hbw]. Frequently,
%               people use use 2*thbw-1, although this is an upper bound, 
%               in some cases K should be << 2*thbw-1. A warning is issued
%               when tapers have concentrations < 0.9.
%     weights - string, optional, default = 'adapt'
%               Algorithm for combining tapered estimates:
%               'adapt'  - Thomson's adaptive non-linear combination 
%               'unity'  - linear combination with unity weights
%               'eigen'  - linear combination with eigenvalue weights
%     robust  - string, optional, default = 'huber'
%               This applies only when SampledProcess has more than one
%               window, in which case it specifies how the estimates in
%               each window should be combined:
%               'mean'     - simple arithmetic mean, NaN's excluded
%               'median'   - median, NaN's excluded
%               'huber'    - robust location using Huber weights
%               'logistic' - robust location using logistic weights
%
%     If method = 'welch'
%     window  - scalar, optional, default = 8 segments with overlap samples
%     overlap - scalar, optional, default = 50% overlap between segments
%
% OUTPUTS
%     obj    - SpectralProcess
%
% EXAMPLES
%     t = (0:.001:5)';
%     s = SampledProcess(2*cos(2*pi*10*t)+cos(2*pi*50*t)+randn(size(t)),'Fs',1000);
%     p = s.psd('hbw',1,'f',0:.25:75);
%     plot(p)
%
% SEE ALSO
%     pmtm, pwelch

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process

% TODO
%  o confidence intervals
%  o quadratic bias
%  o circular welch
%  o when section-averaging, do not recalculate tapers, this may requires
%    sorting the windows
function obj = psd(self,varargin)

p = inputParser;
p.KeepUnmatched = true;
p.FunctionName = 'SampledProcess psd method';
p.addParameter('method','mtm',@(x) any(strcmp(x,...
   {'multitaper' 'mtm' 'welch'})));
p.addParameter('f',[],@(x) isnumeric(x) && isvector(x));
p.addParameter('type','psd',@ischar);
p.parse(varargin{:});
params = p.Unmatched;
par = p.Results;

nObj = numel(self);
obj(nObj,1) = SpectralProcess();
for i = 1:nObj
   obj(i) = psdEach(self(i),par,params);
end

%%
function tfr = psdEach(obj,par,params)

Fs = obj.Fs;
if isempty(par.f)
   f = linspace(0,Fs/2,100);
else
   f = par.f;
end

switch lower(par.method)
   case {'mtm' 'multitaper'}
      % Total time. If Process has multiple windows, assume that the
      % time-sensitive parameters refer to the maximum extent convered by
      % the windows.
      T = max(obj.relWindow(:)) - min(obj.relWindow(:));
      if isfield(params,'hbw')
         params.thbw = T*params.hbw;
      elseif isfield(params,'thbw')
         params.hbw = params.thbw/T;
      else
         params.thbw = 4;
         params.hbw = params.thbw/T;
      end
      
      sectionAvg = false;
      if numel(obj.values) > 1
         sectionAvg = true;
         if ~isfield(params,'robust')
            params.robust = 'mean';
         end
         N = T*obj.Fs;
      else
         N = obj.dim{1}(1);
      end
      
      if ~isfield(params,'weights')
         params.weights = 'adapt';
      end
      
      % There are less than 2*nw-1 tapers with good concentration in the
      % band [-hbw hbw]. Default is frequently to use 2*thbw-1, although
      % this is an upper bound, and some suggest K << 2*thbw-1.
      % Last taper is dropped automatically
      K = min(round(2*params.thbw),N) - 1;
      if ~isfield(params,'K')
         params.K = max(K,2);
      else
         assert((params.K>=2) && (params.K<=K),...
            '# of tapers must be greater than 2 and < 2*nw-1');
      end
      
      if sectionAvg
         nSections = size(obj.window,1);
         Twin = obj.relWindow(:,2) - obj.relWindow(:,1);
         temp = zeros(numel(f),obj.n,nSections);
         for i = 1:nSections
            % Adjust thbw & K to maintain desired hbw given the section length
            params.thbw(i) = Twin(i)*params.hbw;
            params.K(i) = max(2,min(round(2*params.thbw(i)),N) - 1);
            [E,V] = dpss(obj.dim{i}(1),params.thbw(i),params.K(i));
            params.Vfrac(i) = sum(V>=0.9)/length(V);
            %params.V{i} = V(:);
            
            if any(V<0.9)
               warning(strcat('%g tapers are not well concentrated with',...
                  ' eigenvalues < 0.9.\n%g tapers will be used.',...
                  ' Consider reducing to ensure unbiasedness'),...
                  sum(V<0.9),params.K(i));
            end
            
            temp(:,:,i) = pmtm(obj.values{i},E,V,f,Fs,...
               'DropLastTaper',false,params.weights);
         end
         
         temp = permute(temp,[1 3 2]);
         
         p = zeros(numel(f),obj.n);
         for i = 1:obj.n
            %TODO: should issue warning on NaNs?
            switch params.robust
               case {'mean'}
                  p(:,i) = mean(temp(:,:,i),2);
               case {'median'}
                  p(:,i) = nanmedian(temp(:,:,i),2);
               case {'huber'}
                  p(:,i) = stat.mlochuber(temp(:,:,i)','k',5)';
               case {'logistic'}
                  p(:,i) = stat.mloclogist(temp(:,:,i)','loc','nanmedian','k',5)';
            end
         end
      else
         [E,V] = dpss(N,params.thbw,params.K);
         params.Vfrac = sum(V>=0.9)/length(V);
         %params.V = V(:);
         
         if any(V<0.9)
               warning(strcat('%g tapers are not well concentrated with',...
                  ' eigenvalues < 0.9.\n%g tapers will be used.',...
                  ' Consider reducing to ensure unbiasedness'),...
                  sum(V<0.9),params.K);
         end
         
         p = pmtm(obj.values{1},E,V,f,Fs,'DropLastTaper',false,params.weights);         
      end
      
      tBlock = max(obj.relWindow(:)) - min(obj.relWindow(:));
      tStep = tBlock;
      tStart = min(obj.relWindow(:));
      tEnd = max(obj.relWindow(:));
      
      if isrow(p)
         p = p';
      end
      
   case {'welch'}
      if ~isfield(params,'window')
         params.window = [];
      end
      if ~isfield(params,'overlap')
         params.overlap = [];
      end
      p = pwelch(obj.values{1},params.window,params.overlap,f,Fs);

      tBlock = max(obj.relWindow(:)) - min(obj.relWindow(:));
      tStep = tBlock;
      tStart = min(obj.relWindow(:));
      tEnd = max(obj.relWindow(:));
end

P = zeros([1 size(p)]);
P(1,:,:) = p;

tfr = SpectralProcess(P,...
   'f',f,...
   'params',params,...
   'tBlock',tBlock,...
   'tStep',tStep,...
   'labels',obj.labels,...
   'tStart',tStart,...
   'tEnd',tEnd...
   );
