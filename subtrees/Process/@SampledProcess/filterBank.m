% FILTERBANK - Filter SampledProcess values using a bank of filters
%
%     filterBank(SampledProcess,f,varargin)
%     SampledProcess.filterBank(f,varargin)
%
%     Given and array f of filters, the SampledProcess is passed through
%     each filter. 
%
%     All inputs are passed in using name/value pairs. The name is a string
%     followed by the value (described below).
%     The order of the pairs does not matter, nor does the case.
%
% INPUTS
%     f - array of filters
%
%     Extra parameters passed through to SampledProcess.filter
%
% OUTPUTS
%     out - SampledProcess of same dimension as input, each containing 
%           [# of original channels x filters] channels
%
% EXAMPLES
%
%     SEE ALSO
%     filter, filtfilt

%     $ Copyright (C) 2016 Brian Lau <brian.lau@upmc.fr> $
%     Released under the BSD license. The license and most recent version
%     of the code can be found on GitHub:
%     https://github.com/brian-lau/Process
function out = filterBank(self,f,varargin)

p = inputParser;
p.KeepUnmatched = true;
addRequired(p,'f',@(x) isnumeric(x) ...
                    || ~isempty(strfind(class(x),'dfilt')) ...
                    || isa(x,'digitalFilter'));
parse(p,f,varargin{:});
par = p.Results;
filtPar = p.Unmatched;

nObj = numel(self);

% Check all FIR/linearPhase, switch to filtfilt if necessary
usefiltfilt = false;

for i = 1:nObj
   n = self(i).n;
   len = self(i).dim{1}(1);
   nF = numel(f);
   temp = copy(self(i));
   
   x = zeros(len,nF*n);
   for j = 1:nF
      if usefiltfilt
         temp.filtfilt(f(j),filtPar);
      else
         temp.filter(f(j),filtPar);
      end
      ind = (1:n)+(j-1)*n;
      x(:,ind) = temp.values{1};
      temp.reset();
   end

   out(i) = SampledProcess(x,...
      'Fs',self(i).Fs,...
      'labels',copy(repmat(self(i).labels,1,nF)),...
      'tStart',self(i).relWindow(1),...
      'tEnd',self(i).relWindow(2)...
      );
   
   clear x labels;
end