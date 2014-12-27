% patients = {'CAMJa' 'CANFr' 'HANJe' 'HOFCl' 'MERDi' 'MORGe' 'NEUDi' 'PINMa' 'RACTh'};
% deline   = {true    true    true    true    true    true    true    true    true};
patients = {'CAMJa' 'BAUMa' 'CALVi'};
deline   = {true    true    true};

basedir = '/Volumes/library';
savedir = '/Volumes/library/STN';
overwrite = false;

task = 'BASELINEASSIS';
condition = 'OFF';
for i = 1:numel(patients)
   winpsd('patient',patients{i},'basedir',basedir,'savedir',savedir,...
      'condition',condition,'task',task,'deline',deline{i},...
      'overwrite',overwrite);
end
condition = 'ON';
for i = 1:numel(patients)
   winpsd('patient',patients{i},'basedir',basedir,'savedir',savedir,...
      'condition',condition,'task',task,'deline',deline{i},...
      'overwrite',overwrite);
end
