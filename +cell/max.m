% Max of elements in cell array
function y = max(x)

cMax = cellfun(@max,x,'uniformoutput',false);
y = max([cMax{:}]);
