% s.bandpass('Fstop1',100,'Fpass1',120,'Fpass2',300,'Fstop2',310,'verbose',true,'plot',true);
function [self,h,d] = bandpass(self,varargin)

if nargin < 2
   error('SampledProcess:bandpass:InputValue',...
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
addParameter(p,'attenuation1',60,@isnumeric); % Stopband attenuation in dB
addParameter(p,'attenuation2',60,@isnumeric); % Stopband attenuation in dB
addParameter(p,'ripple',0.1,@isnumeric); % Passband ripple in dB
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
      d = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2',...
         par.Fstop1,par.Fpass1,par.Fpass2,par.Fstop2,par.attenuation1,par.ripple,par.attenuation2,self(i).Fs);
   else % specified-order filter
      if ~isempty(par.Fc1) && ~isempty(par.Fc2) % 6dB cutoff
         d = fdesign.bandpass('N,Fc1,Fc2,Ast1,Ap,Ast2',...
            par.order,par.Fc1,par.Fc2,par.attenuation1,par.ripple,par.attenuation2,self(i).Fs);
      else
         error('SampledProcess:bandpass:InputValue',...
            'Incomplete filter design specification');
      end
   end
   
   if isempty(par.method)
      h = design(d,'MinOrder','even');
   else
      h = design(d,par.method,'MinOrder','odd');
   end
   
   if par.plot
      fvtool(h);
   end
   
   if par.verbose
      info(h,'long');
   end
   
   if ~par.designOnly
      self(i).filter(h);
   end
end
