% BANDSTOP - Design and optionally apply bandstop filter to SampledProcess
%
%     [self,h,d,hft] = bandstop(SampledProcess,varargin)
%     SampledProcess.bandstop(varargin)
%
%     The default is to filter using an linear-phase even-order FIR filter,
%     designed with an equiripple or least-squares design algorithm (depends
%     on call sequence, see INPUTS). For very stringent specifications, 
%     this may fail to converge or take too long. It may be worthwhile to 
%     switch to a window design method (see OPTIONAL and EXAMPLES below).
%
%     Data is filtered using a single-pass, compensating for the delay
%     imposed by the designed filter (see SampledProcess.filter).
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
%                Fpass1                          Fpass2
%                  v                                .   .  -
%             |. . .    -                          . . .     ripple2
%             | . . .   _ ripple1                 .   .    _  
%             |      .                           .       a
%             |       .                         .        t
%             |      ^ .                       . ^       t
%             |     Fc1 .                     . Fc2      e
%             |          .                   .           n
%             |           .                 .            u
%             |            .               .             a
%             |             .             .              t
%             |              .           .               i
%             |               . . . . . .                o
%             |                . . . . .                 n
%             |               ^         ^         
%             |             Fstop1    Fstop2
%             ____________________________________________
%
% INPUTS
%     Fpass1 - Frequency at end of first passband
%     Fpass2 - Frequency at start of second passband
%     Fstop1 - Frequency at start of stopband
%     Fstop2 - Frequency at end of stopband
%     Fc1    - Cutoff frequency at 6dB point below first passband value
%     Fc2    - Cutoff frequency at 6dB point below second passband value
%     order  - Filter length - 1
%
%     There are 2 different ways to call this function using combinations
%     of the above above variables.
%     1) Fpass1 & Fstop1 & Fstop2 & Fpass2. This designs a minimum-order 
%        equiripple filter meeting design specs. 
%     2) order & Fc1 & Fc2. This designs an linear-phase FIR filter using 
%        constrained least-squares to meet design specs using given order. 
%        Order should be even for an integer group delay.
%
% OPTIONAL
%     attenuation - scalar (decibels), optional, default = 60
%     ripple1     - scalar (decibels), optional, default = 0.01
%     ripple2     - scalar (decibels), optional, default = 0.01
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
%     bandpass, highpass, lowpass, filter, filtfilt

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process
function [self,h,d,hft] = bandstop(self,varargin)

if nargin < 2
   error('SampledProcess:bandstop:InputValue',...
      'Must at least specify ''Fc1/2'' and ''order''.');
end

Fs = unique([self.Fs]);
if numel(Fs) > 1
   error('SampledProcess:bandstop:InputValue',...
      strcat('Cannot calculate common filter for different sampling frequencies.\n',...
      'Use arrayfun if you really want to calculate a different filter for each element.'));
end

p = inputParser;
p.KeepUnmatched = true;
addParameter(p,'Fpass1',[],@isnumeric);
addParameter(p,'Fpass2',[],@isnumeric);
addParameter(p,'Fstop1',[],@isnumeric);
addParameter(p,'Fstop2',[],@isnumeric);
addParameter(p,'Fc1',[],@isnumeric);
addParameter(p,'Fc2',[],@isnumeric);
addParameter(p,'order',[],@isnumeric);
addParameter(p,'attenuation',60,@isnumeric); % Stopband attenuation in dB
addParameter(p,'ripple1',0.01,@isnumeric); % Passband ripple in dB
addParameter(p,'ripple2',0.01,@isnumeric); % Passband ripple in dB
addParameter(p,'method','',@ischar);
addParameter(p,'plot',false,@(x) islogical(x) || isa(x,'sigtools.fvtool'));
addParameter(p,'verbose',false,@islogical);
addParameter(p,'designOnly',false,@islogical);
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
         assert(~isempty(par.Fpass1)&&~isempty(par.Fpass2)&&~isempty(par.Fstop1)&&~isempty(par.Fstop2),...
            'Minimum order filter requires Fpass1/2 and Fstop1/2 to be specified.');
         d = fdesign.bandstop('Fp1,Fst1,Fst2,Fp2,Ap1,Ast,Ap2',...
            par.Fpass1,par.Fstop1,par.Fstop2,par.Fpass2,par.ripple1,par.attenuation,par.ripple2,self.Fs);
      else % specified-order filter
         if ~isempty(par.Fc1) && ~isempty(par.Fc2) % 6dB cutoff
            d = fdesign.bandstop('N,Fc1,Fc2,Ap1,Ast,Ap2',...
               par.order,par.Fc1,par.Fc2,par.ripple1,par.attenuation,par.ripple2,self.Fs);
         else
            error('SampledProcess:bandstop:InputValue',...
               'Incomplete filter design specification');
         end
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
               err2 = MException('SampledProcess:bandstop:InputValue',...
                  strcat('For this parameter sequence, valid methods are restricted to: ',...
                  msg));
            else
               err2 = MException('SampledProcess:bandstop:InputValue',...
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
   if islogical(par.plot) || ~isvalid(par.plot)
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
