% patient - 4 letter id string
% coord - 'acpc' or 'stn'
% dipole - '01G' '23D', etc

% x,y,z are localizations depending on coordinate system

function [x,y,z] = getDBSloc(patient,coord,dipole,side)

persistent text patients sides coords dipoles X Y Z;

if isempty(text)
   fid = fopen('/Users/brian/Downloads/NormalizedACPC_YEB_Coordinates.txt');
   
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
   
   patients = {};
   sides = {};
   coords = {};
   dipoles = {};
   for i = 1:numel(text)
      temp = strsplit(text{i});
      temp2 = strsplit(temp{2},'_');
      patients{i,1} = temp2{end};

      temp2 = strsplit(temp{3},'_');
      if strcmp(temp2{1}(1),'L')
         sides{i,1} = 'G';
      else
         sides{i,1} = 'D';
      end
      
      dipoles{i,1} = [temp2{3}(1) temp2{3}(3)];
      
      if strcmp(temp2{3}(4),'A')
         coords{i,1} = 'ACPC';
      else
         coords{i,1} = 'STN';
      end
      
      X(i,1) = str2num(temp{5}(2:end));
      Y(i,1) = str2num(temp{7}(2:end));
      Z(i,1) = str2num(temp{9}(2:end));
   end
end

if nargin == 3
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