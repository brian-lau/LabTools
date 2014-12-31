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
         'task',tasks{j},'overwrite',overwrite);
   end
end


% for i = 1:numel(info)
%    i
%    for j = 1:numel(tasks)
%          plotwinpsd('patient',info(i).PATIENTID,'basedir',basedir,'savedir',savedir,...
%             'task',tasks{j},'overwrite',overwrite);
%    end
% end
% 
%          plotwinpsd('patient','RICDi','basedir',basedir,'savedir',savedir,...
%             'task','BASELINEASSIS','overwrite',overwrite);
%          plotwinpsd('patient','RICDi','basedir',basedir,'savedir',savedir,...
%             'task','BASELINEDEBOUT','overwrite',overwrite);
%          