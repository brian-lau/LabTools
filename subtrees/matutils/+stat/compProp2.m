% compProp2                  Compare two proportions
% 
%     [h,p,stat] = compProp2(observed,flag,alpha,tail);
%
%     Compare two (possibly stratified) proportions.
%
%     INPUTS
%     observed - 2x2(xS) table of counts. Row margin is assumed fixed, so
%                p1 is defined by column 1 and p2 is defined by column 2.
%                For stratified data, the third dimension represents strata.
%
%     OPTIONAL
%     flag     - 1, Z-test (consistent with confidence interval)
%                2, Pearson chi2 test
%                3, Pearson chi2 test with Yate's continuity correction
%                4, Pearson chi2 test with (N-1), default
%                5, Likelihood-ratio chi2 test (G-test)
%                6, Fisher exact test
%                7, Cochran-Mantel-Haenszel test
%     alpha    - significance level (100*alpha), default=0.05
%     tail     - 'both'  p1 ~= p2 (default)
%                'right' p1 > p2
%                'left'  p1 < p2
%
%     OUTPUTS
%     h        - boolean indicating whether null is rejected 
%     p        - p-value
%     stat     - statistic
%
%     SEE ALSO
%     compPropRxC

% Example 1 from: http://www.jerrydallal.com/LHSP/p.htm
% p1 = 8/13; p2 = 3/13;
% compProp2([8 3 ; 13-8 13-3]);
%
% SAS example from: http://udel.edu/~mcdonald/statgtestind.html
% compProp2([190 42; 149 49]);
%
% Example 24.15 from Zar. Biostatistical Analysis, 5th ed. pg. 549
% [h,p,stat] = compProp2([18 10 ; 24-18 25-10],2,[],'both') % two-tailed 
% [h,p,stat] = compProp2([18 10 ; 24-18 25-10],2,[],'right') % one-tailed, p1 > p2
% [h,p,stat] = compProp2([18 10 ; 24-18 25-10],2,[],'left') % one-tailed, p1 < p2
%
% Stratified data example  from: http://udel.edu/~mcdonald/statcmh.html
% observed = cat( 3, [56 69; 40 77], [61 257; 57 301], [73 65; 71 79] , [71 48; 55 48])
% [h,p,stat] = compProp2(observed,7)

%     $ Copyright (C) 2011-2012 Brian Lau http://www.subcortex.net/ $
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
%     brian 08.25.11 written

function [h,p,stat] = compProp2(observed,flag,alpha,tail)

import stat.*

if nargin < 4 || isempty(tail)
   tail = 'both';
end
if nargin < 3 || isempty(alpha)
   alpha = 0.05;
end
if nargin < 2 || isempty(flag)
   flag = 4;
end

if nargout == 0
   str = {'Z-test                              '...
          'Chi-square                          '...
          'Continuity Adj. Chi-Square          '...
          '(N-1) Chi-Square                    '...
          'Likelihood ratio Chi-square         '...
          'Fisher exact test                   '...
          'Cochran-Mantel-Haenszel test        '};
   fprintf('Statistic                            Value      Prob\n');
   fprintf('------------------------------------------------------------\n');
   for i = 1:7
      [h,p,stat] = compProp2(observed,i,alpha,tail);
      fprintf('%s %1.4f\t%1.4f\n',str{i},stat,p);
   end
   return
end

[m n l] = size(observed);

if (m~=2) || (n~=2)
   error('First two dimensions must be 2x2 to compProb2');
end

if (l>1) && (strcmpi(flag,'cmh') || (flag~=7))
   warning('Data is stratified, forcing Cochran-Mantel-Haenszel test');
   flag = 7;
end

n11 = observed(1,1,:);
n12 = observed(1,2,:);
n21 = observed(2,1,:);
n22 = observed(2,2,:);

if (flag<4) | strcmpi(flag,'pearson') | strcmpi(flag,'chi2') | strcmpi(flag,'yates') | strcmpi(flag,'likelihood') | strcmpi(flag,'g')
   n1 = sum(observed(:,1));
   p1 = n11 / n1;
   q1 = 1 - p1;
   n2 = sum(observed(:,2));
   p2 = n12 / n2;
   q2 = 1 - p2;
   p = sum(observed(1,:)) ./ (n1 + n2);
   q = 1 - p;
end

switch lower(flag)
   case {1 'z'}
      % Z-test, Consistent with confidence interval
      z = (p1 - p2) / sqrt( (p1*q1/n1) + (p2*q2/n2) );
   case {2 'chi2' 'pearson'}
      % Z-test, Equivalent to Pearson chi2 test
      z = (p1 - p2) / sqrt( p*q*(1/n1 + 1/n2) );
   case {3 'yates'}
      % Z-test, Equivalent to Pearson chi2 test with Yate's continuity correction
      z = (abs(p1 - p2) - 0.5*(1/n1 + 1/n2)) ./ sqrt( p*q*(1/n1 + 1/n2) );
   case {4 'n-1'}
      % Pearson chi2 test using N-1 in numerator
      % https://sites.google.com/a/lakeheadu.ca/bweaver/Home/statistics/notes/chisqr_assumptions
      N = sum(sum(observed));
      stat = (N-1)*(n11*n22 - n12*n21)^2 / ((n11+n21)*(n12+n22)*(n11+n12)*(n21+n22));
      p = 1 - chi2cdf(stat,1);
      h = p <= alpha;
      return;
   case {5 'likelihood' 'g'}
      % Likelihood-ratio chi2 test (G-test)
      if ~strcmpi(tail,'both')
         warning('Two-tailed test forced when using G-test.');
      end
      [h,p,stat] = compPropRxC(observed,'likelihood');
      return;
   case {6 'fisher'}
%       % Fisher exact test http://www.mathworks.com/matlabcentral/fileexchange/5957-fisherextest
%       [Ppos,Pneg,Pboth] = Fisherextest(n11,n12,n21,n22);
%       switch lower(tail)
%          case 'both'
%             p = Pboth;
%          case 'left'
%             p = Ppos;
%          case 'right'
%             p = Pneg;
%          otherwise
%             error('Bad TAIL to compProp2');
%       end
%       h = p <= alpha;
%       stat = NaN;
      h = nan;
      p = nan;
      stat = nan;
      return;
   case {7 'cmh'}
      % Cochran-Mantel-Haenszel test
      if ~strcmpi(tail,'both')
         warning('Two-tailed test forced when using Cochran-Mantel-Haenszel test.');
      end
      n11 = observed(1,1,:);
      n12 = observed(1,2,:);
      n21 = observed(2,1,:);
      n22 = observed(2,2,:);
      n_1 = sum(observed(:,1,:),1);
      n_2 = sum(observed(:,2,:),1);
      n1_ = sum(observed(1,:,:),2);
      n2_ = sum(observed(2,:,:),2);
      n__ = n11 + n12 + n21 + n22;
      
      stat = ( abs( sum(n11 - (n_1.*n1_)./n__,3) ) )^2 / sum( (n_1.*n_2.*n1_.*n2_) ./ (n__.^2 .*(n__-1)),3);
      % Continuity-corrected
      %stat = ( abs( sum(n11 - (n_1.*n1_)./n__,3) ) - 0.5 )^2 / sum( (n_1.*n_2.*n1_.*n2_) ./ (n__.^2 .*(n__-1)),3);
      p = 1 - chi2cdf(stat,1);
      h = p <= alpha;
      return;
   otherwise
      error('Bad FLAG to compProp2!');
end

% for the z-tests only
switch lower(tail)
   case 'both'
      p = 2*(1 - normcdf(abs(z)));
   case 'left'
      p = normcdf(z);
   case 'right'
      p = 1 - normcdf(z);
   otherwise
      error('Bad TAIL to compProp2');
end

h = p <= alpha;
stat = z;

