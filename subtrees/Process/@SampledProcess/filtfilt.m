% FILTFILT - Zero-phase filtering of SampledProcess values
%
%     filtfilt(SampledProcess,f,varargin)
%     SampledProcess.filtfilt(f,varargin)
%
%     Data filtered using a forward and backward pass (two-pass) to achieve
%     zero-phase shift. This effectively doubles the filter order and 
%     squares the stopband attenuation and passband ripple, which should be 
%     taken into account when designing filters or determining the actual 
%     attenuation and cutoffs applied to filtered data.
%
%     Do not use filtfilt if you are filtering with linear-phase FIR
%     filters. Besides the issue above of changing ripple/attenuation, it
%     is much slower than SampledProcess.filter (see example). filtfilt is 
%     useful when using IIR/nonlinear-phase FIR filters and zero-phase
%     shift is required.
%
% INPUTS
%     f - numeric vector | dfilt object | designFilter object, required
%
% EXAMPLES
%     t = (0:.001:1)';
%     s = SampledProcess(cos(2*pi*7*t)+0.25*randn(length(t),1),'Fs',1000);
%     % Linear-phase lowpass FIR filter with passband ending at 20 Hz
%     d = fdesign.lowpass('Fp,Fst,Ap,Ast',20,40,0.01,60,s.Fs);
%     f = design(d,'equiripple','minOrder','even');
%     h = plot(s);
%     s.filtfilt(f);
%     plot(s,'handle',h);
%
%     % compare to causal filter
%     s.reset().filter(f,'compensateDelay',false).plot('handle',h);
%
%     % In the case of linear-phase FIR filters, there is no reason to use
%     % filtfilt, which is much slower than filter (one-pass, FFT)
%     s.reset;
%     [~,f,d,hh] = s.lowpass('Fpass',20,'Fstop',40,'designOnly',true,...
%        'plot',0,'verbose',0);
%     % Two-pass filtfilt
%     h = plot(s.filtfilt(f));
%     % One-pass filter. Filters are linear, and the cascade of two filters
%     % is equivalent to filtering with the convolution of the two filters
%     s.reset;
%     plot(s.filter(conv(f.Numerator,f.Numerator)),'handle',h)
%     % Differences occur at the edges, due to different treatment of end
%     % effects
%
%     SEE ALSO
%     filter

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process

% TODO
%   o batched (looped) filtering (eg. for memmapped data)
%   o filter state for managing contiguous blocks? eg., chopped process
%   o nan's anywhere will result in all nans with filtfilt
function self = filtfilt(self,f,varargin)

p = inputParser;
p.KeepUnmatched = true;
addRequired(p,'f',@(x) isnumeric(x) ...
                    || ~isempty(strfind(class(x),'dfilt')) ...
                    || isa(x,'digitalFilter'));
parse(p,f,varargin{:});
par = p.Results;

if isnumeric(f) && isvector(f)
   f = dfilt.dffir(f);
end

for i = 1:numel(self)
   %------- Add to function queue ----------
   if isQueueable(self(i))
      addToQueue(self(i),par);
      if self(i).deferredEval
         continue;
      end
   end
   %----------------------------------------

   for j = 1:size(self(i).window,1)
      if isa(f,'digitalFilter')
         self(i).values{j} = filtfilt(f,self(i).values{j});
      else
         reset(f);
         self(i).values{j} = sig.filtfilthd(f,self(i).values{j});
      end
   end
end
