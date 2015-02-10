basedir = '/Volumes/Data/Human/STN/MATLAB';
savedir = '/Volumes/Data/Human/STN/MATLAB';
overwrite = true;
conditions = {'OFF' 'ON'};
%tasks = {'BASELINEASSIS' 'BASELINEDEBOUT'};
tasks = {'BASELINEASSIS' 'BASELINEDEBOUT' 'REACH' 'MSUP'};

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
         
         % PASEl & CLANi need to be normalized differently
         if strcmp(info(i).PATIENTID,'CLANi') && strcmp(tasks{j},'BASELINEASSIS')
            out = winpsdstats('patient',info(i).PATIENTID,'basedir',basedir,'savedir',savedir,...
               'condition',conditions{k},'task',tasks{j},'normalize_range',[1 50]);
         elseif strcmp(info(i).PATIENTID,'PASEl')
            out = winpsdstats('patient',info(i).PATIENTID,'basedir',basedir,'savedir',savedir,...
               'condition',conditions{k},'task',tasks{j},'normalize_range',[1 50]);
         else
            out = winpsdstats('patient',info(i).PATIENTID,'basedir',basedir,'savedir',savedir,...
               'condition',conditions{k},'task',tasks{j});
         end
         if ~isempty(out)
            m(i,j,k).L_peakLoc = out(1).peakLoc;
            m(i,j,k).L_peakMag = out(1).peakMag;
            m(i,j,k).L_peakDetected = out(1).peakDetected;
            m(i,j,k).L_truePeak = out(1).truePeak;
            m(i,j,k).L_bandmax = out(1).bandmax;
            m(i,j,k).L_bandavg = out(1).bandavg;
            m(i,j,k).L_offavg = out(1).offavg;
            m(i,j,k).L_power = out(1).power;
            m(i,j,k).f = out(1).f;
            
            m(i,j,k).R_peakLoc = out(2).peakLoc;
            m(i,j,k).R_peakMag = out(2).peakMag;
            m(i,j,k).R_peakDetected = out(2).peakDetected;
            m(i,j,k).R_truePeak = out(2).truePeak;
            m(i,j,k).R_bandmax = out(2).bandmax;
            m(i,j,k).R_bandavg = out(2).bandavg;
            m(i,j,k).R_offavg = out(2).offavg;
            m(i,j,k).R_power = out(2).power;
            m(i,j,k).f = out(2).f;
         else
            m(i,j,k).L_peakLoc = nan(1,3);
            m(i,j,k).L_peakMag = nan(1,3);
            m(i,j,k).L_peakDetected = nan(1,3);
            m(i,j,k).L_truePeak = nan(1,3);
            m(i,j,k).L_bandmax = nan(1,3);
            m(i,j,k).L_bandavg = nan(1,3);
            m(i,j,k).L_offavg = nan(1,3);
            m(i,j,k).L_power = nan(1,3);
            %m(i,j,k).f = NaN;
            
            m(i,j,k).R_peakLoc = nan(1,3);
            m(i,j,k).R_peakMag = nan(1,3);
            m(i,j,k).R_peakDetected = nan(1,3);
            m(i,j,k).R_truePeak = nan(1,3);
            m(i,j,k).R_bandmax = nan(1,3);
            m(i,j,k).R_bandavg = nan(1,3);
            m(i,j,k).R_offavg = nan(1,3);
            m(i,j,k).R_power = nan(1,3);
            %m(i,j,k).f = NaN;
         end
      end
   end
end

% have info and m now