% LabTools path
function setpath(basedir)

if nargin == 0
   basedir = pwd;
end

% need a non-standard command for the following line
addpath(fullfile(basedir,'subtrees','matutils'));
pathStr = os.genpath_exclude(basedir,{'.git' 'Testing'});
addpath(pathStr);

% check for and remove certain fieldtrip paths which shadow functions