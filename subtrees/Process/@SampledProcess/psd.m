function obj = psd(self,varargin)

p = inputParser;
p.KeepUnmatched= true;
p.FunctionName = 'SampledProcess psd method';
p.addParameter('method','mtm',@(x) any(strcmp(x,...
   {'chronux' 'multitaper' 'mtm'})));
p.addParameter('f',0:100,@(x) isnumeric(x) && isvector(x));
p.addParameter('type','psd',@ischar);
p.parse(varargin{:});
params = p.Unmatched;
par = p.Results;

nObj = numel(self);
obj(nObj,1) = SpectralProcess();
for i = 1:nObj
   obj(i) = psdEach(self(i),par,params);
end

%%
function tfr = psdEach(obj,par,params)

fn = fieldnames(params);

switch lower(par.method)
   case {'mtm' 'multitaper'}
      Fs = obj.Fs;
      f = par.f;
      if isempty(fn) || ~isfield(params,'nw')
         nw = 4;
      else
         nw = params.nw;
      end
      
      sectionAvg = false;
      if numel(obj.values) > 1
         sectionAvg = true;
      end
      
      if sectionAvg
         nSections = size(obj.window,1);
         N = max(obj.relWindow(:)) - min(obj.relWindow(:));
         W = nw/N;
         p = zeros(numel(f),nSections);
         for i = 1:nSections
            % issue warning when nw too small
            params.nw(i) = max(1.25,(obj.relWindow(i,2) - obj.relWindow(i,1))*W);
            p(:,i) = pmtm(obj.values{i},params.nw(i),f,Fs);
         end
         %should issue warning on NaNs?
         p = nanmean(p,2);
         
         tBlock = max(obj.relWindow(:)) - min(obj.relWindow(:));
         tStep = tBlock;
         tStart = min(obj.relWindow(:));
         tEnd = max(obj.relWindow(:));
      else
         p = pmtm(obj.values{1},nw,f,Fs);
         tBlock = diff(obj.relWindow);
         tStep = tBlock;
         tStart = obj.relWindow(1);
         tEnd = obj.relWindow(2);
      end
      
      if isrow(p)
         p = p';
      end
      
   case {'chronux'}
%       params.tapers = [12 2*12-1];
%       params.fpass = [min(par.f) max(par.f)];
%       params.Fs = obj.Fs;
%       [p,f] = mtspectrumc(obj.values{1},params);
end

P = zeros([1 size(p)]);
P(1,:,:) = p;

tfr = SpectralProcess(P,...
   'f',f,...
   'params',params,...
   'tBlock',tBlock,...
   'tStep',tStep,...
   'labels',obj.labels,...
   'tStart',tStart,...
   'tEnd',tEnd...
   );
