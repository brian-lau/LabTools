%http://udel.edu/~mcdonald/statchiind.html

% Reproduce example 23.1 from Zar. Biostatistical Analysis, 5th ed.
% [h,p,stat] = compPropRxC([32 43 16 9; 87-32 108-43 80-16 25-9],'pearson')
%
% Two proportions may be compared by casting the underlying data in a 2 x 2 
% contingency table and considering that one margin of the table is fixed 
% 18/24 vs 10/25
% [h,p,stat] = compPropRxC([18 10 ; 24-18 25-10],'pearson')
% 

function [h,p,stat] = compPropRxC(observed,flag,alpha)

if nargin < 3 || isempty(alpha)
   alpha = 0.05;
end
if nargin < 2 || isempty(flag)
   flag = 'likelihood';
end

N = sum(sum(observed));
[r c] = size(observed);
dof = (r-1)*(c-1);

sumR = sum(observed);
sumC = sum(observed,2);
expected = (sumC/N)*sumR;

switch lower(flag)
   case 'pearson' % Score-based chi2
      stat = sum(sum(((observed - expected).^2) ./ expected));
   case 'likelihood' % Likelihood-ratio chi2
      stat = 2*sum(sum(observed .* log(observed./expected)));
   otherwise
      error('Bad FLAG to compPropRxC');
end

p = 1 - chi2cdf(stat,dof);
h = p <= alpha;

