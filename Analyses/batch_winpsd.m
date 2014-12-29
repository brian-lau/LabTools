basedir = '/Volumes/Data/Human/STN/MATLAB';
savedir = '/Volumes/Data/Human/STN/MATLAB';
overwrite = false;
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


for i = 1:numel(info)
   i
   for j = 1:numel(tasks)
      for k = 1:numel(conditions)
         temp = info(i);
         temp = rmfield(temp,'DELINE');

         winpsd('patient',info(i).PATIENTID,'basedir',basedir,'savedir',savedir,...
            'condition',conditions{k},'task',tasks{j},'deline',logical(info(i).DELINE),...
            'overwrite',overwrite,'data',temp,'dataName','clinic');
      end
   end
end

% task = 'BASELINEASSIS';
% for i = 1:numel(patients)
%    plotwinpsd('patient',patients{i},'basedir',basedir,'savedir',savedir,...
%       'task',task);
% end
