function [fstart, fstop, n, err] = getUniformApprox(f)
f = sort(f(:));
fstart = f(1);
fstop = f(end);
n = numel(f);
err = max(abs(f.'-linspace(fstart,fstop,n))./max(abs(f)));