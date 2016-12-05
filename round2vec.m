function rounded = round2vec(varargin)
%ROUND2VEC rounds numbers to closest elements in a vector
%  ROUND2VEC(data,round_vector)
%
%   Given an N-dimensional array of numbers, this function will round all
%   the elements of the array to the nearest elements in the supplied
%   vector.
%
%   Example:
%   data = rand(2,9)*10; %your data vector that you want to round
%   roundvec = [1 2 3.14 8]; %the numbers you want to round the data to
%   rounded = ROUND2VEC(data,roundvec);
%
%   By default the function acts like 'round.m' in terms of rounding
%   direction. The following optional methods can be called as follows:
%   rounded = ROUND2VEC(data,roundvec,method); where 'method' (string) =
%           'round'     (default: round towards nearest)
%           'floor'     (round towards -infinity)
%           'ceil'      (round towards +infinity)
%
%   The function will not attempt to replace NaNs.

%   Author: Owen Brimijoin - MRC/CSO Institute of Hearing Research
%   Date 09/07/14
% Copyright (c) 2014, W. Owen Brimijoin
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
%     * Neither the name of the  nor the names
%       of its contributors may be used to endorse or promote products derived
%       from this software without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.

%input handling:
switch nargin,
    case {0,1}
        error('Not enough input arguments')
    case {2}
        data = varargin{1}; roundvec = varargin{2}; method = 'round';
    case {3}
        data = varargin{1}; roundvec = varargin{2}; method = varargin{3};
    otherwise
        error('Incorrect number of input arguments')
end

%find any NaNs in the data and replace with zeros:
nan_idx = isnan(data);
data(nan_idx) = 0;

%create array of all subtractions between data and roundvec:
diff_array = bsxfun(@minus,roundvec(:),data(:)');

%adjust the diff_array according to rounding 'method':
switch lower(method),
    case 'round'
        %do no adjustment of diff_array
        
    case 'floor'
        % set > entries to -Inf (to exclude ceiling values):
        diff_array(diff_array>0) = -Inf;
        
    case 'ceil'
        % set < entries to +Inf (to exclude floor values):
        diff_array(diff_array<0) = +Inf;
        
    otherwise
        error('Method not recognized')
end

%sort to find index of closest elements:
[~,idx] = sort(abs(diff_array));

%use indices output the data rounded to nearest vector element:
rounded = reshape(roundvec(idx(1,:)),size(data));

%replace the NaNs that were ignored:
rounded(nan_idx) = NaN;

%the end