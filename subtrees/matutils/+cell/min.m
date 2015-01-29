% Min of elements in cell array
function y = min(x)

cMin = cellfun(@min,x,'uniformoutput',false);
y = min([cMin{:}]);
