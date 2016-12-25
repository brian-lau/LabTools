% Smoothly broken power-law fit
function [beta,fval,exitflag] = fit_smbrokenpl(f,p,model,beta0)

import stat.baseline.*


% % TODO, implement cutoff frequency or range to restrict fit
% ind = f>=self.baseParams.f0;%f~=0;
% fnz = f(ind);   % restricted frequencies
% pnz = p(ind,:); % restricted power

nChan = size(p,2);

fnz = f;
pnz = p;

switch model
   case {'broken-power' 'bp' 'bp2'}
      if ~exist('beta0','var')
         beta0 = [1   -2  1  1   30];
      end
      lb = [0   -10  0    0      5];      % lower bounds
      ub = [inf  10  15    15    100];    % upper bounds
   case {'broken-power3' 'bp3'}
      if ~exist('beta0','var')
         beta0 = [1   -1  0.5  1   30 -1 1 500];
      end
      lb = [0   -10  0    0   5    -5  0   100];      % lower bounds
      ub = [inf  10  15   15  100   5  15  1000];    % upper bounds
end

opts = optimoptions('fmincon','MaxFunEvals',15000,...
   'Algorithm','sqp','Display','final');
beta = zeros(length(beta0),nChan);

for chan = 1:nChan
   % Fit using asymmetric error (TODO
   fun = @(b) sum( asymwt(log(smbrokenpl(b,fnz)),log(pnz(:,chan))) );
   %fun = @(b) sum( asymwt((smbrokenpl(b,fnz)),(pnz(:,chan))) );
   
   [beta1,fval1,exitflag1] = ...
      fmincon(fun,beta0,[],[],[],[],lb,ub,@smbrokenpl_constraint,opts);
   beta0(2) = -beta0(2);
   
   if 0
      [beta2,fval2,exitflag2] = ...
         fmincon(fun,beta0,[],[],[],[],lb,ub,@smbrokenpl_constraint,opts);
      
      if fval1 < fval2
         beta = beta1;
         fval = fval1;
         exitflag = exitflag1;
      else
         beta = beta2;
         fval = fval2;
         exitflag = exitflag2;
      end
   else
      beta = beta1;
      fval = fval1;
      exitflag = exitflag1;
   end
end
