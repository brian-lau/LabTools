% Collect cell array elements along a dimension
% 
% c{1,1} = [1 2 3 4 5];
% c{2,1} = [6 7 8 9 10]';
% c{1,2} = [11 12 13 14 15]';
% c{2,2} = 16:20;

function fc = collect(c,dim)

if nargin < 2
   dim = 1;
end

% Force all elements to column format
c = cellfun(@(y) y(:),c,'uniformoutput',false);
dims = size(c);

% Make sure we are only trying to combine arrays
bool = cellfun(@isnumeric,c,'uniformoutput',false);
bool = cat(1,bool{:});
if sum(bool) ~= prod(dims)
   error('Only works for cells with numeric elements');
end

if dim > dims
   error('Bad size');
end

if dim == 1
   for i = 1:dims(2)    % JKB EDIT HERE. used to say '1:dims(1)'. if collapsing across dim1, loop through dim2
      fc{1,i} = cat(1,c{:,i});
   end
elseif dim == 2
   for i = 1:dims(1)
      fc{i,1} = cat(1,c{i,:});
   end
end
