basedir = '/Volumes/Data/Human/STN/MATLAB';
savedir = '/Volumes/Data/Human/STN/MATLAB';
overwrite = true;
conditions = {'OFF' 'ON'};
tasks = {'BASELINEASSIS' 'BASELINEDEBOUT'};
%tasks = {'BASELINEASSIS' 'BASELINEDEBOUT' 'MSUP' 'REACH'};

f = [0:.25:250]';

[NUM,TXT,RAW] = xlsread(fullfile(savedir,'PatientInfo.xlsx'));
labels = RAW(1,:);
RAW(1,:) = [];
n = size(RAW,1);
for i = 1:numel(labels)
   [info(1:n).(labels{i})] = deal(RAW{:,i});
end

[a,b] = intersect({info.PATIENTID}, {'CANFr'});
info = info(b);

%% Calculate spectra
for i = 1:numel(info)
   i
   for j = 1:numel(tasks)
      for k = 1:numel(conditions)
         temp = info(i);
         temp = rmfield(temp,'DELINE');

         winpsd('patient',info(i).PATIENTID,'basedir',basedir,'savedir',savedir,...
            'condition',conditions{k},'task',tasks{j},...
            'f',f,'overwrite',overwrite,'data',temp,'dataName','clinic');
      end
      plotwinpsd('patient',info(i).PATIENTID,'basedir',basedir,'savedir',savedir,...
         'ylim',[-2 25],...
         'task',tasks{j},'overwrite',overwrite);
   end
end
