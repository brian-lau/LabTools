% import matlab.unittest.TestSuite;
% import matlab.unittest.TestRunner;
% import matlab.unittest.plugins.CodeCoveragePlugin
% 
% suite = TestSuite.fromPwd;
% 
% runner = TestRunner.withTextOutput;
% 
% runner.addPlugin(CodeCoveragePlugin.forFolder(pwd))
% result = runner.run(suite);
% 

suite = matlab.unittest.TestSuite.fromFolder(pwd);
runner = matlab.unittest.TestRunner.withTextOutput;
dir = '/Users/brian/Documents/Code/Repos/LabTools/subtrees/Process/@SampledProcess';
runner.addPlugin(matlab.unittest.plugins.CodeCoveragePlugin.forFolder(dir));
result = runner.run(suite);
table(result)