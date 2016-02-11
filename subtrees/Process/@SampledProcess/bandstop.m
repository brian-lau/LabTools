function [self,h,d] = bandstop(self,varargin)

if nargin < 2
   error('SampledProcess:bandstop:InputValue',...
      'Must at least specify ''Fc1/2'' and ''order''.');
end

p = inputParser;
p.KeepUnmatched = true;
addParameter(p,'Fpass1',[],@isnumeric);
addParameter(p,'Fpass2',[],@isnumeric);
addParameter(p,'Fstop1',[],@isnumeric);
addParameter(p,'Fstop2',[],@isnumeric);
addParameter(p,'Fc1',[],@isnumeric);
addParameter(p,'Fc2',[],@isnumeric);
addParameter(p,'order',[],@isnumeric);
addParameter(p,'attenuation',60,@isnumeric); % Stopband attenuation in dB
addParameter(p,'ripple1',0.1,@isnumeric); % Passband ripple in dB
addParameter(p,'ripple2',0.1,@isnumeric); % Passband ripple in dB
addParameter(p,'method','',@ischar);
addParameter(p,'plot',false,@islogical);
addParameter(p,'verbose',false,@islogical);
addParameter(p,'designOnly',false,@islogical);
parse(p,varargin{:});
par = p.Results;

for i = 1:numel(self)
   %------- Add to function queue ----------
   if isQueueable(self(i))
      addToQueue(self(i),par);
      if self(i).deferredEval
         continue;
      end
   end
   %----------------------------------------
   
   if isempty(par.order) % minimum-order filter
      assert(~isempty(par.Fpass1)&&~isempty(par.Fpass2)&&~isempty(par.Fstop1)&&~isempty(par.Fstop2),...
         'Minimum order filter requires Fpass1/2 and Fstop1/2 to be specified.');
      d = fdesign.bandstop('Fp1,Fst1,Fst2,Fp2,Ap1,Ast,Ap2',...
         par.Fpass1,par.Fstop1,par.Fstop2,par.Fpass2,par.ripple1,par.attenuation,par.ripple2,self(i).Fs);
   else % specified-order filter
      if ~isempty(par.Fc1) && ~isempty(par.Fc2) % 6dB cutoff
         d = fdesign.bandstop('N,Fc1,Fc2,Ap1,Ast,Ap2',...
            par.order,par.Fc1,par.Fc2,par.ripple1,par.attenuation,par.ripple2,self(i).Fs);
      else
         error('SampledProcess:bandstop:InputValue',...
            'Incomplete filter design specification');
      end
   end
   
   if isempty(par.method)
      h = design(d,'FilterStructure','dffir');
   else
      h = design(d,par.method,'FilterStructure','dffir');
   end
   
   if par.plot
      fvtool(h);
   end
   
   if par.verbose
      info(h,'long');
   end
   
   if ~par.designOnly
      self(i).filter(h.Numerator,'a',1);
   end
end