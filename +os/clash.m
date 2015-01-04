function [Iout] = clash(string,option)
%CLASH	Test for name collision
%
%       CLASH(string), where string is either a single
%       string, a string matrix, or the name of
%       a file containing the strings to search for,
%       prints the strings that collide with M, Mex,
%       or MAT file names on the MATLABPATH.
%
%	Files containing lists of names should have one
%	name per line.
%
%	CLASH(string,1) prints out messages for each
%	string, CLASH(string) only reports clashes.
%
%	I = CLASH(string) produces a vector of 1's and 0's.
%	1's for names that clash, and 0's otherwise.
%
%	Ex:
%		clash('xlabel')
%		clash(['xlabel.m';'quadblah'],1)
%		clash('/path/filename')
%		I = clash(['xlabel.m';'quadblah'])
%
%               ******* file *******
%	        xlabel.m
%		foobar
%		andrew.mat
%		********************
%
%		clash('file')

%       Copyright (c) 1984-96 by The MathWorks, Inc.

[a,b] = size(string);

if (a == 1)
  if any(string == '/') | (exist(['./' string]) == 2)
    file = fopen(string,'r');
    if file == -1
      disp(['File ' string ' not found'])	
      return
    end	
    words = fread(file)';
    words = words(find((words ~= 32) & (words ~= 9)));
    words = words(filter([1 1],2,words == 10) ~= 1);
    ind = find(words == 10);
    if length(words) ~= ind(length(ind))
      ind = [ind length(words)+1];
    end	
    ind = [0 ind];
    lengths = diff(ind);
    string = 32*ones(length(ind)-1,max(lengths)-1);
    for j = 1:length(lengths)
      string(j,1:lengths(j)-1) = words(ind(j)+1:(ind(j)+lengths(j)-1));
    end
    string = setstr(string);
    [a,b] = size(string);
  end
end

for i = 1:a
  c  = exist(string(i,find(string(i,:) ~= 32)));
  if ~any(string(i,:) == '.')
    c2 = exist([string(i,find(string(i,:) ~= 32)),'.mat']);
  else
    c2 = 0;
  end	
  I(i) = (c == 2) | (c == 3) | (c == 4) | (c == 5) | (c2 == 2);
  if (nargout ~= 1)
    if (c == 0) & (nargin > 1)
      disp([string(i,:) '  OK']);
    elseif (c == 2) | (c == 3) | (c == 4)
      if ~isempty(find(string(i,:)== '.'))
	disp([string(i,:) ' clashes with ' which(string(i,find(string(i,1:find(string(i,:) == '.')-1) ~= 32)))]);
      else
	disp([string(i,:) ' clashes with ' which(string(i,find(string(i,:) ~= 32)))]);
      end			
    elseif (c == 5)
      disp([string(i,:) ' clashes with built-in function ' upper(string(i,:))]);
    elseif (c2 == 2)
      disp([string(i,:) ' clashes with ' which([string(i,find(string(i,:) ~= 32)) '.mat'])]);
    elseif (c == 1)
      disp([string(i,:) ' is a variable in this script']);
    end			
  end
end

if (nargout == 1)
  Iout = I;
  return
end


