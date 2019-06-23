% FILTER - Filter SampledProcess values
%
%     filter(SampledProcess,f,varargin)
%     SampledProcess.filter(f,varargin)
%
%     For linear-phase FIR filters data is filtered using a single-pass, 
%     and by default, filter delay is compensated by shifting filtered 
%     values by the group delay of the filter.
%
%     For nonlinear-phase FIR or IIR filters data is filtered using filtfilt
%     by default, which cascades a forward and backward pass (two-pass).
%     This effectively doubles the filter order and squares the stopband 
%     attenuation and passband ripple, which should be taken into account 
%     when designing filters or determining the actual attenuation and 
%     cutoffs applied to filtered data.
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% INPUTS
%     f - numeric vector | dfilt object | designFilter object, required
%     compensateDelay - bool, optional, default = True
%         Compensate for delay induced by filter. 
%         If false, data is filtered using a single-pass. Delay depends on
%         filter, and can be examined using grpdelay(f).
%         If true, behavior depends on the filter (see above) 
%         If f is a linear-phase FIR filter, delay compensated by shifting
%         filtered values by the group delay of the filter (single-pass). 
%         For nonlinear-phase FIR or IIR filters, data is filtered by
%         cascading a forward and backward pass (two-pass, see above).
%     padmode - string, optional, default = 'sym'
%         Determines how edge effects are treated.
%         Only relevant when compensateDelay = True.
%         'sym' - pad ends with reflected data length equal to group delay
%         'zpd' - pad ends with zeros equal in length to group delay
%
% EXAMPLES
%     t = (0:.001:1)';
%     s = SampledProcess(cos(2*pi*10*t)+0.25*randn(length(t),1),'Fs',1000);
%     % Linear-phase lowpass FIR filter with passband ending at 20 Hz
%     d = fdesign.lowpass('Fp,Fst,Ap,Ast',20,40,0.01,60,s.Fs);
%     f = design(d,'equiripple','minOrder','even');
%     h = plot(s);
%     s.filter(f);
%     plot(s,'handle',h);
%
%     s.reset().filter(f,'compensateDelay',false).plot('handle',h);
%     legend('original','filter - compensated','filter - no compensation');
%
%     SEE ALSO
%     filtfilt, bandpass, bandstop, lowpass

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process

% TODO
%   o batched (looped) filtering (eg. for memmapped data)
%   o filter state for managing contiguous blocks? eg., chopped process
%   o nan's anywhere will result in all nans with filtfilt
%   o match padmode when calling down to filtfilthd
%   o cascade vector of filters
function self = filter(self,f,varargin)

p = inputParser;
p.KeepUnmatched = true;
addRequired(p,'f',@(x) isnumeric(x) ...
                    || ~isempty(strfind(class(x),'dfilt')) ...
                    || isa(x,'digitalFilter'));
addParameter(p,'compensateDelay',true,@(x) islogical(x) || isscalar(x));
addParameter(p,'padmode','sym',@(x) any(strcmp(x,{'sym' 'zpd'})));
parse(p,f,varargin{:});
par = p.Results;

if isnumeric(f) && isvector(f)
   f = dfilt.dffir(f);
end

usefiltfilt = false;
if par.compensateDelay
   if isfir(f) && islinphase(f)
      gd = (impzlength(f) - 1) / 2;
      if rem(gd,1) % type II or IV
         disp('Filter has non-integer group delay, using fix(group delay)');
         gd = fix(gd);
      end
   else
      warning('SampledProcess:filter:nonlinearPhase',...
         'FiltFilt will be used to compensate delay.');
      usefiltfilt = true;
   end
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
      if par.compensateDelay
         if usefiltfilt
            if isa(f,'digitalFilter')
               self(i).values{j} = filtfilt(f,self(i).values{j});
            else
               reset(f);
               self(i).values{j} = sig.filtfilthd(f,self(i).values{j});
            end
         else
            temp = self(i).values{j};
            switch par.padmode
               case 'sym'
                  temp = [temp(gd+1:-1:2,:) ; temp ; temp(end-1:-1:end-gd,:)];
               case'zpd'
                  temp = [zeros(gd,self(i).n) ; temp ; zeros(gd,self(i).n)];
            end
            temp = filter_local(f,temp);
            self(i).values{j} = temp(2*gd+1:2*gd+self(i).dim{j}(1),:);
         end
      else
         self(i).values{j} = filter_local(f,self(i).values{j});
      end
   end
end

%% Decide between filtering in time or frequency domain
function y = filter_local(f,x)
L = size(x,1);
N = impzlength(f);
if isfir(f) && (log2(L) < N) % For FIR filters, FFT can be much faster
   if isa(f,'dfilt.dffir')
      y = fftfilt(f.Numerator,x);
   else % designFilter
      y = fftfilt(f,x);
   end
else
   y = filter(f,x);
end

