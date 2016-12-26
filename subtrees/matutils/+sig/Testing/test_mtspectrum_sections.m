%% multiple sections, slightly different peak frequencies
clear all;
T = 5;
Fs = 2048;
s = fakeLFP2(Fs,T,6);

x{1} = repmat(s.values{1}(:,1),1,3);
x{2} = repmat(s.values{1}(:,1),1,3);
x{3} = repmat(s.values{1}(:,1),1,3);
x{4} = repmat(s.values{1}(:,1),1,3);
x{5} = repmat(s.values{1}(:,1),1,3);

% return individual sections
[out,par] = sig.mtspectrum(x,'hbw',.75,'f',0:.1:1000,'Fs',s.Fs,'Ftest',true,...
   'mask',logical([1 0 0; 0 1 0 ; 0 0 1 ; 0 0 0 ; 1 1 1]),...
   'robust','none');

% Manually calculate location estimate
temp = out.P;
p = nan(par.nf,par.Nchan);
robust = 'logistic';
for i = 1:par.Nchan
   if isempty(par.mask)
      pSection = temp(:,:,i);
   else
      pSection = temp(:,par.mask(:,i),i);
   end
   
   %TODO: should issue warning on NaNs?
   if ~isempty(pSection)
      switch lower(robust)
         case {'median'}
            p(:,i) = median(pSection,2);
         case {'huber'}
            p(:,i) = stat.mlochuber(pSection','k',5)';
         case {'logistic'}
            p(:,i) = stat.mloclogist(pSection','loc','nanmedian','k',5)';
         otherwise
            p(:,i) = mean(pSection,2);
      end
   end
end

% calculate in function
[out,par] = sig.mtspectrum(x,'hbw',.75,'f',0:.1:1000,'Fs',s.Fs,'Ftest',true,...
   'mask',logical([1 0 0; 0 1 0 ; 0 0 1 ; 0 0 0 ; 1 1 1]),...
   'robust',robust);

plot(out.f,p-out.P);


%% check error
[out,par] = sig.mtspectrum(x,'hbw',.75,'f',0:.1:1000,'Fs',s.Fs,'Ftest',true,...
   'mask',logical([0 1 0 ; 0 0 1 ; 0 0 0 ; 1 1 1]),...
   'robust',robust);

[out,par] = sig.mtspectrum(x,'hbw',.75,'f',0:.1:1000,'Fs',s.Fs,'Ftest',true,...
   'mask',double([1 0 0; 0 1 0 ; 0 0 1 ; 0 0 0 ; 1 1 1]),...
   'robust',robust);

