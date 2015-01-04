% Convert nested cell to a flat cell
%
% {{a}, b, {c}}} --> {a,b,c}
% 
% Posted by Yair Altman
% http://blogs.mathworks.com/loren/2006/06/21/cell-arrays-and-their-contents/
% This works very quickly, for any type of input (cell/non-cell), and any 
% type of data (numeric/strings/?).

function data = decell(data)

try
   data = cellfun(@decell,data,'un',0);
   if any(cellfun(@iscell,data))
      data = [data{:}];
   end
catch
   % a non-cell node, so simply return node data as-is
end