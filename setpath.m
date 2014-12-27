% LabTools path

basedir = pwd;

addpath(fullfile(basedir,'STL'));

pathStr = os.genpath_exclude(pwd,{'.git' 'Testing'});

addpath(pathStr);