% event
% params

function [out,b] = myspect2(data,eventName,varargin)

data.reset();
if nargout == 2
   b = getTrialInfo(data);
end
window = [-1 2];

varargin{end+1} = 'window';
varargin{end+1} = window;

data.sync(varargin{:})
temp = linq(data).select(@(x) x.extract('lfp'))...
   .select(@(x) x.extract()).toArray;

for i = 1:numel(data)
   if data(i).validSync
      
      d = data(i).extract('lfp');
      Fs = d{1}.Fs;
      values = temp(i).values;
      params = struct('Fs',Fs,'tapers',[1 2],'fpass',[0 100],'pad',2);
      [S,t,f] = mtspecgramc(values,[.3 .03],params);
      out.S(i,1).trial = S;
   else
      out.S(i,1).trial = [];
   end
end
   
out.event = eventName;
out.t = t + window(1);
out.f = f;

