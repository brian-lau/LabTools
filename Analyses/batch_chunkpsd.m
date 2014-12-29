% patients = {'CAMJa' 'CANFr' 'HANJe' 'HOFCl' 'MERDi' 'MORGe' 'NEUDi' 'PINMa' 'RACTh'};
% deline   = {true    true    true    true    true    true    true    true    true};
patients = {'BAUMa' 'CALVi' 'CLANi' 'CONCh' 'CORDa' 'DESPi' 'FRELi' 'LECCl' 'LEVDa' 'MARDi' 'PASEl' 'REBSy' 'RICDi' 'ROUDo' 'ROYEs' 'SOUJo' 'VIOMa'};
deline   = {true    true    true    true    false   true   true     false   true    false   true    false   false   true    false   true    false};

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

% task = 'BASELINEASSIS';
% for i = 1:numel(patients)
%    plotwinpsd('patient',patients{i},'basedir',basedir,'savedir',savedir,...
%       'task',task);
% end
% 
% 
% plotwinpsd('patient',patients{9},'basedir',basedir,'savedir',savedir,...
%       'task',task);
