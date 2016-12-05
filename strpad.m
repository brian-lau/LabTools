%STRPAD pads a string with any number of char either at the start or the
%end
%
% % To pad the string ABC with zeros ('0') at the front to make it 8
% % characters long ('i.e. 00000ABC')
%  strpad('ABC',8,'pre','0')
%
% % To pad the string Hello with zeros ('Q') at the end to make it 14
% % characters long ('i.e. HelloQQQQQQQQQ')
%  strpad('Hello',14,'post','Q')
%
% % To pad the String 101010 with ones ('1') so that it is 16 characters
% % long (i.e. '1111111111101010'). Note by default padding is 'pre'
%  strpad('101010',16)
%
% % Error cases:
% % - Not passing in a string
%
% % Warning cases:
% % - Not passing in the required number of character
% %  -- Default: return the string passed in
% % - Passing in a string which is longer than the character requested
% %  -- Default: return the string passed in
% % - Passing in more than 1 padding character
% %  -- Default: is to pad with '0's

% Copyright (c) 2012, Gavin
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.

function stringReturn = strpad(stringPassed,totalChars,charPosition,fillChar)
if nargin == 0
   stringReturn = '';
   return;
end

if nargin<4
   fillChar = '0';
   if nargin<3
      charPosition='pre';
      if nargin<2
         warning('You must pass the required totalChars'); %#ok<WNTAG>
         stringReturn = stringPassed;
         return;
      end
   end
end

if length(stringPassed)>=totalChars
   warning('The string is already longer than the required pad value');     %#ok<WNTAG>
   return;
end
if size(fillChar,1) ~= 1 || size(fillChar,2) ~=1
   warning('The fill char pass is too large using 0 (zeros) instead');     %#ok<WNTAG>
   fillChar = '0';
end

% Go through from the current length to the desired length the required len
stringReturn = stringPassed;
for i=length(stringPassed)+1:totalChars
   if strcmp(charPosition,'pre')
      stringReturn = [fillChar,stringReturn];     %#ok<AGROW>
   elseif strcmp(charPosition,'post')
      stringReturn = [stringReturn,fillChar];     %#ok<AGROW>
   end
end

end