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
%               people use 2*thbw-1, although this is an upper bound, 
%               in some cases K should be << 2*thbw-1.
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
%     See sig.mtspectrum for more options.
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
%     sig.mtspectrum, pwelch

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
      params.Fs = obj.Fs;
      params.f = f;
      
      [out,par] = sig.mtspectrum(obj.values,params);
      p = out.P;
      params = par;

      tBlock = max(obj.relWindow(:)) - min(obj.relWindow(:));
      tStep = tBlock;
      tStart = min(obj.relWindow(:));
      tEnd = max(obj.relWindow(:));
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
