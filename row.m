% Create a row vector from a matrix X = [x1 x2 ... xn] by stringing rows

function y = row(X)

y = vec(X')';