% Smoothly broken power-law fit
function [beta,fval,exitflag] = fit_smbrokenpl(f,p,model,beta0)

import stat.baseline.*

nChan = size(p,2);

switch model
   case {'broken-power' 'bp' 'bp2'}
      if ~exist('beta0','var') || isempty(beta0)
         beta0 = [1   2  1  1   30];
      end
      lb = [0   -10  0    0      2];      % lower bounds
      ub = [inf  10  15    15    100];    % upper bounds
   case {'broken-power3' 'bp3'}
      if ~exist('beta0','var') || isempty(beta0)
         beta0 = [1   1  0.5  1   30 1 1 500];
      end
      lb = [0   -10  0    0   2    -5  0   100];      % lower bounds
      ub = [inf  10  15   15  100   5  15  1000];    % upper bounds
end

opts = optimoptions('fmincon','MaxFunEvals',15000,...
   'Algorithm','active-set','Display','none');
beta = zeros(length(beta0),nChan);

for chan = 1:nChan
   % Fit using asymmetric error (TODO
   fun = @(b) sum( asymwt(log(smbrokenpl(b,f)),log(p(:,chan))) );
   %fun = @(b) sum( asymwt((smbrokenpl(b,fnz)),(pnz(:,chan))) );
   
   [beta1,fval1,exitflag1] = ...
      fmincon(fun,beta0,[],[],[],[],lb,ub,@smbrokenpl_constraint,opts);
   
   if 1
      beta0(2) = -beta0(2);
      [beta2,fval2,exitflag2] = ...
         fmincon(fun,beta0,[],[],[],[],lb,ub,@smbrokenpl_constraint,opts);
      
      if (exitflag1>0) && (exitflag2>0)
         if fval1 < fval2
            beta(:,chan) = beta1;
            fval(chan) = fval1;
            exitflag(chan) = exitflag1;
         else
            beta(:,chan) = beta2;
            fval(chan) = fval2;
            exitflag(chan) = exitflag2;
         end
      elseif (exitflag1>0) && (exitflag2<=0)
         beta(:,chan) = beta1;
         fval(chan) = fval1;
         exitflag(chan) = exitflag1;
      elseif (exitflag1<=0) && (exitflag2>0)
         beta(:,chan) = beta2;
         fval(chan) = fval2;
         exitflag(chan) = exitflag2;
      else
         beta(:,chan) = beta1;
         fval(chan) = fval1;
         exitflag(chan) = exitflag1;
      end
   else
      beta(:,chan) = beta1;
      fval(chan) = fval1;
      exitflag(chan) = exitflag1;
   end
   
end