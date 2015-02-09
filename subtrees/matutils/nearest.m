% Find element in matrix closest to ref
%http://stackoverflow.com/questions/22609192/find-the-closest-value-in-a-matrix-matlab
function [val,row,col] = nearest(ref,matrix)

% linear index of closest entry
if isscalar(ref)
   [~,ii] = min(abs(matrix(:)-ref));
else
   [~,ii] = min(abs(bsxfun(@minus,matrix(:),ref)));
end
val = matrix(ii);

if nargout > 1
   %% Convert the linear index into row and column numbers
   [row,col] = ind2sub(size(matrix),ii);
end
