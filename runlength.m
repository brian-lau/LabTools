function [l,s] = runlength(x,R)
%function [l,s] = runlength(x,R)
%
% Parses the vector x into "runs" of constant value.
% 
% x   - row or column vector
% R   - maximum run length
%
% l   - length of run
% s   - value of run
%
% Eg. x = [0 0 0 pi pi -1 -1 7 7 7 7 nan inf inf -inf];
%     R = 3;
%
%     l = [ 3     2   2   3   1   1   2    1 ];
%     s = [ 0  3.14  -1   7   7 nan inf -inf ];
%
% Output vectors have the same orientation as the input vector. 

% Owen Kelly June 3, 1998.
% oekelly@winlab.rutgers.edu

sx = size(x);
x = x(:)';                      % force x to be row vector

if nargin < 2
   R = max(sx);
end
   
nanx = isnan(x);
infx = isinf(x);
maxx = max(x(~(nanx|infx)));	% maximum finite number in x

if any( nanx | infx ),

  % Here we bring NANs and INFs into the range of finite numbers so
  % that diff yields 0 where there is a run. Our assumption is that 
  % nannum (as defined below) is finite.

  nannum = sqrt(abs(maxx))*sqrt(realmax);
  infnum = abs(maxx)^(2/3)*realmax^(1/3);

  x(nanx) = nannum;
  x(infx) = infnum*sign(x(infx));  % retain the sign of infinities

  % mx marks with 1 all the places where a run begins in x
  mx = [1;diff(x(:))]~=0; 

  % l are the run lengths
  l = diff([find(mx);length(x)+1])';

  % replace original sequence values
  x(nanx)=nan; 
  x(infx)=x(infx)*inf;

else
  % mx marks with 1 all the places where a run begins in x
  mx = [1;diff(x(:))]~=0; 

  % l are the run lengths
  l = diff([find(mx);length(x)+1])';
end

% s are the symbols at the beginning of each run
s = x(mx);

% At this point l and s are row vectors that give a run-length description 
% of x, but the maximum length has not been considered.


%%%%%%%%% break large runs into repeats of length R %%%%%%%

Rl = floor(l/R);  % determine the maximum  number of repetitions
mRl = max(Rl);    

if mRl > 0,
  dl = l-R*floor(l/R);

  rl = zeros(mRl+1,length(l));  % space to store repetitions

  rl(mRl+1,:) = dl;
  for k=1:mRl,
    rl(k,:) = R*(Rl>=k);
  end

  S = s(ones(mRl+1,1),:);       % create repetitions of symbols

  l = rl(:)';                   % unroll both matrices in time
  s = S(:)';

  lnz = l>0;                    % remove zero length phrases
  l = l(lnz);
  s = s(lnz);
end

% s and l retain the same orientation as x
if diff(sx)<0,
 l=l';
 s = s';
end
