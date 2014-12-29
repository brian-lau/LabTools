% Join pdf files using a system call

% input can be cell array filenames
% if just a str, assumed to be a wildcard expression

% TODO, if cell array, check files exist...
%       if regexp, check empty outputs?
%       return message of system command

% http://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/

function joinPDFs(input,output,deleteInputs)

if nargin < 3
   deleteInputs = false;
end
if nargin < 2
   output = [datestr(now,'yyyymmddTHHMMSSFFF') '.pdf'];
end
comp = computer;

% Expand PDF filenames
if isstr(input)
   inputStr = input;
   d = dir(input);
   inputNames = {d.name};
elseif iscell(input)
   inputStr = sprintf('%s ', input{:});
   inputNames = input;
else
   error('joinPDFs:badInput','Input must be a string expression or cell array of filenames.');
end

% Locate system command for joining pdfs
% Default check is for PDFTK
% On OSX, we switch to a built-in Python wrapper if pdftk is missing, this
% is slower, less space efficient, and inconsistent at handling orientation
switch comp
   case 'MACI64'
      [~,result] = system('which pdftk');
      if isempty(result)
         if exist('/usr/local/bin/pdftk','file') == 2
            syscommand = '/usr/local/bin/pdftk';
         elseif exist('/System/Library/Automator/Combine PDF Pages.action/Contents/Resources/join.py','file') == 2
            syscommand = 'python /System/Library/Automator/Combine\ PDF\ Pages.action/Contents/Resources/join.py';
         else
            error('joinPDFs:pdftkMissing','Can''t find program to join PDFs.');
         end
      else
         syscommand = 'pdftk';
      end
   case {'GLNX86','GLNXA64'}
      [~,result] = system('which pdftk');
      if isempty(result)
         if exist('/usr/local/bin/pdftk','file') == 2
            syscommand = '/usr/local/bin/pdftk';
         else
            error('joinPDFs:pdftkMissing','Can''t find program to join PDFs.');
         end
      else
         syscommand = 'pdftk';
      end
   case {'PCWIN','PCWIN64'}
      
   otherwise
      error('joinPDFs:unknownOS','Don''t know where to find PDFTK on this OS.');
end

if strfind(syscommand,'pdftk')
   %pdftk in1.pdf in2.pdf cat output out1.pdf
   [status,result] = system([syscommand ' ' inputStr ' cat output ' output]);
elseif strfind(syscommand,'join.py')
   %join -o out1.pdf in1.pdf in2.pdf
   [status,result] = system([syscommand ' -o ' output ' ' inputStr]);
else
   % ghostscript?
end

if deleteInputs
   oldState = recycle('on');
   for i = 1:length(inputNames)
      delete(inputNames{i});
   end
   recycle(oldState);
end
