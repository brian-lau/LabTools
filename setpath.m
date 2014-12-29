% LabTools path

basedir = pwd;

addpath(fullfile(basedir,'subtrees','matutils'));

pathStr = os.genpath_exclude(pwd,{'.git' 'Testing'});
addpath(pathStr);