% event
% params

function [out,b] = myspect2(data,event)

window = [-1 2];
b = getTrialInfo(data);

for i = 1:numel(data)
   if ~isnan(data(i).info(event))
      
      if ~isnan(data(i).info(event))
         t = data(i).info(event);
         temp = linq(data(i))...
            .select(@(x) x.sync(t(end),'window',window))...
            .select(@(x) extract(x,'SampledProcess')).toArray();
      end
      
      Fs = data(1).data{1}.Fs;
      values = temp.values{1};
%      params = struct('Fs',Fs,'tapers',[1 2],'fpass',[0 100],'pad',2);
      params = struct('Fs',Fs,'tapers',[2 4],'fpass',[0 100],'pad',2);
      [S,t,f] = mtspecgramc(values,[.3 .03],params);
      out.S(i,1).trial = S;
   else
      out.S(i,1).trial = [];
   end
end
   
out.event = event;
out.t = t + window(1);
out.f = f;
