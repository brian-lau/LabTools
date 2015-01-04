% mapfun                     Apply function to values of a containers.Map
% 
%     [out,keys] = mapfun(fun,map,varargin)
%
%     Functions similarly to cellfun.
%
%     Except for C, the optional inputs are all name/value pairs. The name 
%     is a string followed by the value (described below). The order of the 
%     pairs does not matter, nor does the case.
%
%     INPUTS
%     fun           - Function handle
%     map           - containers.Map object
%  
%     OPTIONAL
%     C             - Cell array of parameters to pass through to FUN. These
%                     are passed through as a comma-separated list
%                     C *must* be passed in following MAP (cf, CELLFUN)
%     keys          - Cell array of keys to apply FUN to (default all keys)
%     UniformOutput - Boolean indicating indicating whether or not the output(s) 
%                     of FUN can be returned without encapsulation in a cell 
%                     array. 
%                     If true (default), FUN must return scalar values that
%                     can be concatenated into an array.
%                     If false, cellfun returns a cell array where the (I)th 
%                     cell contains the value FUN(MAP(keys{I})). When false, 
%                     the outputs can be of any type.
% 
%     OUTPUTS
%     out           - Array or cell array with elements corresponding to the
%                     output of FUN applied to the values corresponding to 
%                     the KEYS in MAP.
%                     When FUN is not valid for a key value, the corresponding
%                     element of OUT is filled with a NaN.
%     keys          - Cell array of keys that FUN was applied to. 
%
%     EXAMPLES
%     % Does map contain a value
%     map = containers.Map({1 2 3},{'a' 'b' -1:1})
%     mapfun(@(x)isequal(x,'a'),map)
%     mapfun(@(x)isequal(x,-1:1),map)
%     mapfun(@(x)isequal(x,'a'),map,'keys',{1 3})
%     % Passing inputs to FUN
%     out = mapfun(@(x,y) x<y,map,{1},'UniformOutput',false)
%     out{3}
%     map(3)
%     out = mapfun(@(x,y,z) (x<y)&(x>z),map,{1},{-1},'UniformOutput',false)
%     out{3}
%     map(3)
%     %
%     map = containers.Map({1 2 3},{'a' 'b' 'rain'});
%     mapfun(@(x,y) fprintf(1,'key %i \t has value %s\n',y,x),map,map.keys);
%     % NaN elements where FUN doesn't work
%     map = containers.Map({1 2 3},{'a' 'b' struct('name','foo','value',100)})
%     out = mapfun(@(x,y) x.value>y,map,{10})
%     out{1}
%     out{2}
%
%     SEE ALSO
%     cellfun

%     $ Copyright (C) 2012 Brian Lau http://www.subcortex.net/ $
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%     REVISION HISTORY:
%     brian 12.11.12 written based on idea from Jochen Rau's foreach
%

function [out,keys] = mapfun(fun,map,varargin)

% Multiple maps passed in
if iscell(map)
   n = length(map);
   for i = 1:n
      if nargout == 1
         out{i} = mapfun(fun,map{i},varargin{:});
      else
         [out{i},keys{i}] = mapfun(fun,map{i},varargin{:});
      end
   end
   return
end

% Collect inputs that passed through to FUN
if ~isempty(varargin)
   inputNames = {'keys' 'UniformOutput'};
   if ~isstr(varargin{1}) || ~any(strcmpi(varargin{1},inputNames))
      if ~iscell(varargin{1})
         error('Input #3 expected to be a cell array.');
      end
      count = 1;
      while 1
         % Pull off arguments until hit a parameter name
         C{count} = varargin{1};
         varargin(1) = [];
         if isempty(varargin) || any(strcmpi(varargin{1},inputNames))
            break;
         end
         count = count + 1;
      end
   else
      C = {};
   end
else
   C = {};
end

%% Parse inputs
p = inputParser;
p.KeepUnmatched= false; 
p.FunctionName = 'mapfun';
p.addRequired('fun',@(x) isa(fun,'function_handle') );
p.addRequired('map',@(x) isa(x,'containers.Map') );
p.addParamValue('keys',map.keys,@iscell);
p.addParamValue('UniformOutput',true,@islogical);
p.parse(fun,map,varargin{:});

keys = p.Results.keys;
if p.Results.UniformOutput
   out = zeros(1,numel(keys));
else
   out = cell(1,numel(keys));
end

% Params are passed through to fun, the same for each key, or a unique set
% for each key
if ~isempty(C)
   nKeys = numel(keys);
   if iscell(C)
      nParams = numel(C);
      for i = 1:nParams
         if iscell(C{i})
            temp = C{i};
         else
            temp = {C{i}};
         end         
         if numel(temp) == 1
            % The same parameters are applied to each key-value
            temp = repmat(temp,1,nKeys);
         elseif numel(temp) ~= nKeys
            error('cat shit');
         end
         params{i} = temp;
      end
   else
      error('Not done');
   end
else
   params = {};
end

values = map.values(keys);
try
   if isempty(params)
      out = cellfun(fun,values,'UniformOutput',p.Results.UniformOutput,'ErrorHandler',@errorfun);
   else
      out = cellfun(fun,values,params{:},'UniformOutput',p.Results.UniformOutput,'ErrorHandler',@errorfun);
   end
catch err
   if strcmp(err.identifier,'MATLAB:minrhs')
      msg = sprintf('Not enough input arguments at index %g.\nSet the params input.',i);
      error('mapfun:InputFormat',msg);
   elseif (strcmp(err.identifier,'MATLAB:cellfun:MismatchInOutputTypes'))
      msg = sprintf('Non-scalar in Uniform output, at index %g.\nSet UniformOutput = false.',i);
      error('mapfun:NonUniformOutput',msg);
   else
      rethrow(err);
   end
end

function result = errorfun(S, varargin)
warning(S.identifier, S.message);
result = NaN;

