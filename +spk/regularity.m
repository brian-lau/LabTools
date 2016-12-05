% regularity                  Regularity statistics for point processes
%
%     stats = regularity(data,varargin)
%     
%     Measures the variability of interspike intervals. Some of the available 
%     methods (cv2, lv, lvr) are superior to standard measures like
%     the coefficient of variation since they are designed to separate the
%     irregularity from the firing rate.
%
%     The optional inputs are all name/value pairs. The name is a string
%     followed by the value (described below). The order of the pairs does
%     not matter, nor does the case.
%
%     INPUTS
%     data         - Two possible formats, one is as as a vector of event 
%                    times or a vector cell array of event times. The second 
%                    format is as a vector or vector cell array of interspike
%                    intervals. If you choose the latter, you must set the
%                    optional 'dataFormat' parameter to 'intervals'.
%  
%     OPTIONAL
%     method       - string or cell array of strings specifying statistics
%                    'cv'  : coefficient of variation
%                    'cv2' : cv for a sequence of two ISIs
%                    'lv'  : local variation, nonstationarity is eliminated 
%                            by rescaling intervals with the momentary rate
%                            Poisson has lv = 1, regular < 1, bursty > 1
%                    'lvr' : version of Lv that corrects for the refractoriness
%                    'ir'  : difference of log ISIs
%     dataFormat   - 'times' (default) data correspond to event times
%                    'intervals' data correspond to interspike intervals
%
%     R - refractoriness constant, default = 0.005 seconds
%
%     OUTPUTS
%     stats        - estimates
%
%     REFERENCE
%     Shinomoto S, Kim H, Shimokawa T, Matsuno N, Funahashi S, et al. (2009)
%     Relating Neuronal Firing Patterns to Functional Differentiation of 
%     Cerebral Cortex. PLoS Comput Biol 5(7): e1000433. 
%     doi:10.1371/journal.pcbi.1000433

%     $ Copyright (C) 2012 Brian Lau http://www.subcortex.net/ $

%
% lv & cv checked here: 
%   http://www.ton.scphys.kyoto-u.ac.jp/~shino/toolbox/english.htm
% Their results only presented to two decimal places
% data = [24 67 92 26 69 96 32 72 104 47 75 107 52 77 110 55 79 112 57 81 120 60,...
%    83 122 62 86 125 64 88 129];
% stats = regularity(x,'method',{'lv' 'cv'}) % lv = 0.25 cv = 0.76 
% data = [0.0097 0.0272 0.0615 0.0779 0.1918 0.2574 0.4438 0.4561 0.7816 0.9658];
% stats = regularity(x,'method',{'lv' 'cv'}) % lv = 1.05 cv = 1.01 

% TODO several of these measures work on local pairs of isis, consider
% returning the vector of metrics rather than, or in addition to, mean?
% cell array inputs
% output formats

function stats = regularity(data,varargin)

import spk.*

%% Parse inputs
p = inputParser;
p.KeepUnmatched= true;
p.FunctionName = 'regularity';
p.addRequired('data',@(x)validateattributes(x,{'numeric' 'cell'},{'vector'}));
validDataFormats = {'times' 'intervals'};
p.addParamValue('dataFormat','times',@(x)any(strcmp(x,validDataFormats)));
validMethods = {'cv' 'cv2' 'lv' 'lvr' 'ir'};
p.addParamValue('method','lvr',@(x)all(ismember(x,validMethods)));
validOutputFormats = {'array' 'struct'};
p.parse(data,varargin{:});
params = p.Unmatched; % passed through to the requested methods

if iscell(data)
   n = numel(data);
   for i = 1:n
      stats(i) = regularity(data{i},varargin{:});
   end
   return;
else   
   if strcmp(p.Results.dataFormat,'times')
      isi = diff(sort(data(:)));
   else
      isi = data;
   end
   
   for i = 1:length(p.Results.method)
      if iscell(p.Results.method)
         method = p.Results.method{i};
      else
         method = p.Results.method;
      end
      
      switch method
         case 'cv'
            stats.cv = std(isi)/mean(isi);
         case 'cv2'
            cv2 = 2 * abs((isi(2:end) - isi(1:end-1))) ./ (isi(2:end) + isi(1:end-1));
            stats.cv2 = mean(cv2);
         case 'lv'
            lv = ( (isi(1:end-1) - isi(2:end)) ./ (isi(1:end-1) + isi(2:end)) ).^2;
            stats.lv = 3*mean(lv);
         case 'lvr'
            R = .005;
            lvr = (1 - (4*isi(1:end-1).*isi(2:end)) ./ ((isi(1:end-1) + isi(2:end)).^2))...
               .*(1 + (4*R)./(isi(1:end-1)+isi(2:end)));
            stats.lvr = 3*mean(lvr);
         case 'ir'
            stats.ir = mean( abs(log( isi(2:end) ./ isi(1:end-1) )) );
         otherwise
      end
   end
end
   