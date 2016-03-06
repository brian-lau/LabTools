% NOTCH - Design and optionally apply notch filter to SampledProcess
%
%     [self,h,d,hft] = notch(SampledProcess,varargin)
%     SampledProcess.notch(varargin)
%
%     The default is to filter using an IIR filter, designed with an 
%     equiripple or least-squares design algorithm 
%
%     Data is filtered using a zero-phase filter (double-pass), compensating 
%     for the delay imposed by the designed filter (see SampledProcess.filter).
%
%     When input is an array of SampledProcesses, will iterate and treat 
%     each using the same filter, provided they all have the sampled
%     sampling frequency. Will error when input is a SampledProcess array 
%     with different sampling frequencies. To filter SampledProcess arrays 
%     with different sampling frequencies, use arrayfun (see EXAMPLES).
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
% 
%                                 BW
%                              |       |             
%             |. . . . . . . .           . . . . . . . .    -   
%             | . . . . . . . .         . . . . . . . .     _  ripple
%             |                .       .                 a
%             |                 .     .                  t
%             |                  .   .                   t
%             |                  .   .                   e
%             |                  .   .                   n
%             |                  .   .                   u
%             |                   . .                    a
%             |                   . .                    t
%             |                   . .                    i
%             |                   . .                    o
%             |                    .                     n
%             |                    ^         
%             |                    F
%             ____________________________________________
%
% INPUTS
%     F     - Notch frequency
%     BW    - 3-dB bandwidth
%     order - Filter length - 1
%
% OPTIONAL
%     attenuation - scalar (decibels), optional, default = 60
%     ripple      - scalar (decibels), optional, default = 0.01
%     method      - string, optional, default depends on call, defined above
%     plot        - boolean, optional, default = False
%                   Plot properties of filter
%     verbose     - boolean, optional, default = False
%                   Print detailed report of filter properties
%     designOnly  - boolean, optional, default = True
%                   Design the filter without filtering SampledProcess
%
% OUTPUTS
%     self - reference to SampledProcess
%     h    - filter object (this can be re-used with SampledProcess.filter)
%     d    - filter design object
%     hft  - handle to filter plot
%
% EXAMPLES
%     s = SampledProcess(randn(1000,1),'Fs',1000);
%     % Filter process
%     s.bandstop('order',200,'Fc1',50,'Fc2',100);
% 
%     % Compare equiripple default to other design algorithms
%     [~,h,d,hh] = s.bandstop('Fpass1',30,'Fstop1',60,...
%                  'Fstop2',100,'Fpass2',130,'designOnly',true,...
%                  'plot',true,'verbose',true);
%     s.bandstop('Fpass1',30,'Fstop1',60,...
%                  'Fstop2',100,'Fpass2',130,'designOnly',true,...
%                  'plot',hh,'verbose',true,'method','kaiserwin');
%     s.bandstop('order',100,'Fc1',45,'Fc2',115,'designOnly',true,'plot',hh,...
%                  'method','fircls','verbose',true);
%     legend('equiripple','kaiser','cls')
%
%     % Processing SampledProcess arrays with mixed sampling frequencies
%     s(1) = SampledProcess(randn(1000,1),'Fs',1000);
%     s(2) = SampledProcess(randn(2000,1),'Fs',2000);
%     arrayfun(@(x) x.bandstop('order',200,'Fc1',50,'Fc2',100),s,'uni',0);
%
%     SEE ALSO
%     bandstop, bandpass, highpass, lowpass, filter, filtfilt

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process
function [self,h,d,hft] = notch(self,varargin)

if nargin < 2
   error('SampledProcess:notch:InputValue',...
      'Must at least specify ''F'' and ''order''.');
end

Fs = unique([self.Fs]);
if numel(Fs) > 1
   error('SampledProcess:notch:InputValue',...
      strcat('Cannot calculate common filter for different sampling frequencies.\n',...
      'Use arrayfun if you really want to calculate a different filter for each element.'));
end

p = inputParser;
p.KeepUnmatched = true;
addParameter(p,'F',[],@isnumeric);
addParameter(p,'BW',5,@isnumeric);
addParameter(p,'order',[],@isnumeric);
addParameter(p,'attenuation',60,@isnumeric); % Stopband attenuation in dB
addParameter(p,'ripple',0.01,@isnumeric); % Passband ripple in dB
addParameter(p,'method','',@ischar);
addParameter(p,'plot',false,@(x) isscalar(x) || isa(x,'sigtools.fvtool'));
addParameter(p,'verbose',false,@(x) islogical(x) || isscalar(x));
addParameter(p,'designOnly',false,@(x) islogical(x) || isscalar(x));
parse(p,varargin{:});
par = p.Results;
designPars = p.Unmatched;

for i = 1:numel(self)
   %------- Add to function queue ----------
   if isQueueable(self(i))
      addToQueue(self(i),par);
      if self(i).deferredEval
         continue;
      end
   end
   %----------------------------------------
   
   if i == 1
      if isempty(par.order) % minimum-order filter
            error('SampledProcess:notch:InputValue',...
               'Incomplete filter design specification');
      else % specified-order filter
         d  = fdesign.notch('N,F0,BW,Ap,Ast',...
            par.order,par.F,par.BW,par.attenuation,par.ripple,Fs); %ellip
      end
      
      if isempty(par.method)
         dm = designmethods(d,'default');
         do = designoptions(d,dm{1});
         if isfield(do,'MinOrder')
            % Force even order for integer group delay
            h = design(d,'MinOrder','even');
         else
            h = design(d);
         end
      else
         try
            h = design(d,par.method,designPars);
         catch err
            if strcmp(err.identifier,...
                  'signal:fdesign:abstracttype:superdesign:invalidDesignMethod')
               n = designmethods(d);
               msg = sprintf(' %s, ',n{:});
               err2 = MException('SampledProcess:notch:InputValue',...
                  strcat('For this parameter sequence, valid methods are restricted to: ',...
                  msg));
            else
               err2 = MException('SampledProcess:notch:InputValue',...
                  strcat('Unknown parameters for method: ',par.method));
            end
            err = addCause(err2,err);
            throw(err);
         end
      end
   end % end filter design
   
   if ~par.designOnly
      self(i).filter(h);
   end
end

if isa(par.plot,'sigtools.fvtool') || par.plot
   if islogical(par.plot) || isnumeric(par.plot) || ~isvalid(par.plot)
      hft = fvtool(h);
   else
      addfilter(par.plot,h);
      hft = par.plot;
   end
elseif nargout == 4
   hft = [];
end

if par.verbose
   info(h,'long');
end
