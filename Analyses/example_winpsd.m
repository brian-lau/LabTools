basedir = '/Volumes/Data/Human';
savedir = '/Volumes/Data/Human/STN/MATLAB';
overwrite = true;
area = 'STN';
recording = 'Postop';
patient = 'HOFCl';
%condition = 'OFF';
task = 'BASELINEASSIS';

f = [0:.25:250]';

preprocess('area',area,'recording',recording,'patient',patient,'basedir',basedir,'savedir',savedir,...
   'condition','OFF','task',task,'deline',true,'overwrite',overwrite);
preprocess('area',area,'recording',recording,'patient',patient,'basedir',basedir,'savedir',savedir,...
   'condition','ON','task',task,'deline',true,'overwrite',overwrite);

winpsd('patient',patient,'basedir',savedir,'savedir',savedir,...
   'condition','OFF','task',task,'f',f,'overwrite',overwrite);
winpsd('patient',patient,'basedir',savedir,'savedir',savedir,...
   'condition','ON','task',task,'f',f,'overwrite',overwrite);

plotwinpsd('patient',patient,'basedir',savedir,'savedir',savedir,...
   'ylim',[-2 25],...
   'task',task,'overwrite',overwrite);
