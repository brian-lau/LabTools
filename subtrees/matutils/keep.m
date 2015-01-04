function keep(varargin)
%KEEP2 keeps the base workspace variables of your choice and clear the rest.
%	
%     CALL: keep var1 var2 var3 ...
%	
%

if exist('clearvars') == 2
   evalin('caller',['clearvars -except ' char(varargin)]); 
else
   % Yoram Tal 5/7/98    yoramtal@internet-zahav.net
   % MATLAB version 5.2
   % Based on a program by Xiaoning (David) Yang
   
   % Find variables in base workspace
   wh = evalin('base','who');
   
   % Remove variables in the "keep" list
   del = setdiff(wh,varargin);
   
   % Construct the clearing command string
   str = 'clear ';
   for i = 1:length(del),
      str = [str,' ',del{i}];
   end
   
   % Clear
   evalin('base',str)
end