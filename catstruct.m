function S = catstruct(dim, varargin)
%CATSTRUCT Concatenate structures with dissimilar fields
%
%  S = catstruct(dim, A1, A2, A3, ...)
%
% This function concatenates the input structures along the dimension dim.
% The resulting structures contains all fields found in any of the input
% structures.  If an input structure did not originally have that field,
% the new field is left empty.

% Copyright 2008 Kelly Kearney
% The MIT License (MIT)
% 
% Copyright (c) 2015 Kelly Kearney
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy of
% this software and associated documentation files (the "Software"), to deal in
% the Software without restriction, including without limitation the rights to
% use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
% the Software, and to permit persons to whom the Software is furnished to do so,
% subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
% FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
% COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
% IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
% CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

dims = cell2mat(cellfun(@size, varargin, 'uni', 0)');

ndim = length(dims);
checkdim = dims;
checkdim(:,dim) = [];
if length(unique(checkdim, 'rows')) ~= 1
    error('Inconsistent dimensions along concatenation');
end


allfields = cellfun(@fieldnames, varargin, 'uni', 0);
allfields = unique(cat(1, allfields{:}));

for istruct = 1:length(varargin)
    s{istruct} = varargin{istruct};
    for ifield = 1:length(allfields)
        if ~isfield(s{istruct},allfields{ifield})
            [s{istruct}.(allfields{ifield})] = deal([]);
        end
    end
end
        
S = cat(dim, s{:});