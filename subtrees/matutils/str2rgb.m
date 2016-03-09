% Convert one of Matlab's colorspec strings (single character color, eg
% 'k', 'b', 'r', 'w', etc.) to RGB value
% http://www.mathworks.com/matlabcentral/newsreader/view_thread/263933
function C = str2rgb(str)

C = rem(floor((strfind('kbgcrmyw', str) - 1) * [0.25 0.5 1]), 2);