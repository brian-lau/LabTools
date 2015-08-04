% patient - 4 letter id string
% coord - 'acpc' or 'stn'
% dipole - '01' '23', etc
% side - 'D' or 'G'

% x,y,z are localizations depending on coordinate system

function [x,y,z] = getDBSloc(fname,patient,coord,dipole,side)

persistent text patients sides coords dipoles X Y Z;

if isempty(text)
   
   if isempty(text)
      fid = fopen(fname);
      text = {};
      while 1
         tline = fgetl(fid);
         if ~ischar(tline)
            fclose(fid);
            break;
         else
            text = cat(1,text,tline);
         end
      end
   end
   
   patients = {};
   sides = {};
   coords = {};
   dipoles = {};
   for i = 1:numel(text)
      temp = strsplit(text{i});
      temp2 = strsplit(temp{2},'_');
      patients{i,1} = temp2{end}(1:4);

      temp2 = strsplit(temp{3},'_');
      if strcmp(temp2{6}(1),'L')
         sides{i,1} = 'G';
      else
         sides{i,1} = 'D';
      end
      
      dipoles{i,1} = [temp2{end}(1) temp2{end}(3)];
      
      if strcmp(temp{4}(1),'A')
         coords{i,1} = 'ACPC';
      else
         coords{i,1} = 'STN';
      end
      
      X(i,1) = str2num(temp{6}(2:end));
      Y(i,1) = str2num(temp{8}(2:end));
      Z(i,1) = str2num(temp{10}(2:end));
   end
end

if nargin == 4
   temp = dipole;
   dipole = temp(1:2);
   side = temp(3);
end

ind = strncmpi(patient,patients,numel(patient)) & strcmpi(coords,coord) & strcmpi(dipoles,dipole) & strcmpi(sides,side);

if sum(ind) == 1
   x = X(ind);
   y = Y(ind);
   z = Z(ind);
else
   x = NaN;
   y = NaN;
   z = NaN;
   %error('missing or not unique');
end