function [c,ceq] = smbrokenpl_constraint(x)

c = 0.1 - abs(x(2));
ceq = [];