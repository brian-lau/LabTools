
function [updrs,patient] = fetch_UPDRS(id,exam,ip)

if nargin < 3
   ip = net.ip(); % assume local sharing
end

url = ['jdbc:filemaker://' ip '/patients_STNDBS_122014.fmp12'];
persistent name password;

if iscell(id)
   % parse name
   if (size(id,1)==1) && (size(id,2)==2)
      nom = id{1};
      prenom = id{2};
   else
      % loop
   end
else
   nom = id(1:3);
   prenom = id(4:end);
end

% authenticate DB
if isempty(name) || isempty(password)
   [name,password] = gui.logindlg('Title','Database credentials');
end

% Set DB preferences
setdbprefs('DataReturnFormat','structure');
setdbprefs('NullNumberRead','NaN');
setdbprefs('NullStringRead','null');
%setdbprefs('JDBCDataSourceFile','/Users/brian/Downloads/jdbcConfig.mat');

% Connect to database using JDBC driver.
conn = database('',name,password,'com.filemaker.jdbc.Driver',url);
if conn.Handle == 0
   name = [];
   password = [];
   error(conn.Message);
end

switch lower(exam)
   case {'inclusion'} %% Preop/Inclusion
      sqlquery = [...
         'SELECT Nom , Prenom , Sexe '...
         ' , "Date de naissance" , "Duree d''evolution" , "Date d''intervention" '...
         ' , "Date bilan preoperatoire"'...
         ' , U1 , U2 , U3 , U4 , U5 , U6 , U7 , U8 , U9 , U10 , U11 , U12 '...
         ' , U13 , U14 , U15 , U16 , U17 , U18 , U19 , U20a , U20b , U20c '...
         ' , U20d , U20e , U21a , U21b , U22a , U22b , U22c , U22d , U22e '...
         ' , U23a , U23b , U24a , U24b , U25a , U25b , U26a , U26b , U27 '...
         ' , U28 , U29 , U30 , U31 , U32 , U33 , U34 , U35 , U36 , U37 '...
         ' , U38 , U39 , U40 , U41 , U42 , "H.Yon" , "S.Eon" , U5off '...
         ' , U6off , U7off , U8off , U9off , U10off , U11off , U12off '...
         ' , U13off , U14off , U15off , U16off , U17off , U18off , U19off '...
         ' , U20aoff , U20boff , U20coff , U20doff , U20eoff , U21aoff '...
         ' , U21boff , U22aoff , U22boff , U22coff , U22doff , U22eoff '...
         ' , U23aoff , U23boff , U24aoff , U24boff , U25aoff , U25boff '...
         ' , U26aoff , U26boff , U27off , U28off , U29off , U30off , U31off '...
         ' , "H.Yoff" , "S.Eoff" '...
         ];
      sqlquery2 = [sqlquery ...
         ' FROM Patients '...
         'WHERE Nom LIKE ''' nom '%'' '...
         'AND Prenom LIKE ''' prenom '%'' '...
         'AND Nom NOT LIKE ''%(suite)%'' '...
         ];
   case {'6','6-12','12'}
      sqlquery = [...
         'SELECT Nom , Prenom , Sexe '...
         ' , "Date de naissance" , "Duree d''evolution" , "Date d''intervention" '...
         ' , "Date Mois6"'...
         ' , "U1.6" , "U2.6" , "U3.6" , "U4.6" , "U5.6" , "U6.6" , "U7.6" , "U8.6" , "U9.6" , "U10.6" , "U11.6" , "U12.6" '...
         ' , "U13.6" , "U14.6" , "U15.6" , "U16.6" , "U17.6" '...
         ' , "U18onsofm.6" , "U18off.6" , "U18.6" , "U18onsonm.6" '...
         ' , "U19onsofm.6" , "U19off.6" , "U19.6" , "U19onsonm.6" '...
         ' , "U20aonsofm.6" , "U20aoff.6" , "U20a.6" , "U20aonsonm.6" '...
         ' , "U20bonsofm.6" , "U20boff.6" , "U20b.6" , "U20bonsonm.6" '...
         ' , "U20consofm.6" , "U20coff.6" , "U20c.6" , "U20consonm.6" '...
         ' , "U20donsofm.6" , "U20doff.6" , "U20d.6" , "U20donsonm.6" '...
         ' , "U20eonsofm.6" , "U20eoff.6" , "U20e.6" , "U20eonsonm.6" '...
         ' , "U21aonsofm.6" , "U21aoff.6" , "U21a.6" , "U21aonsonm.6" '...
         ' , "U21bonsofm.6" , "U21boff.6" , "U21b.6" , "U21bonsonm.6" '...
         ' , "U22aonsofm.6" , "U22aoff.6" , "U22a.6" , "U22aonsonm.6" '...
         ' , "U22bonsofm.6" , "U22boff.6" , "U22b.6" , "U22bonsonm.6" '...
         ' , "U22consofm.6" , "U22coff.6" , "U22c.6" , "U22consonm.6" '...
         ' , "U22donsofm.6" , "U22doff.6" , "U22d.6" , "U22donsonm.6" '...
         ' , "U22eonsofm.6" , "U22eoff.6" , "U22e.6" , "U22eonsonm.6" '...
         ' , "U23aonsofm.6" , "U23aoff.6" , "U23a.6" , "U23aonsonm.6" '...
         ' , "U23bonsofm.6" , "U23boff.6" , "U23b.6" , "U23bonsonm.6" '...
         ' , "U24aonsofm.6" , "U24aoff.6" , "U24a.6" , "U24aonsonm.6" '...
         ' , "U24bonsofm.6" , "U24boff.6" , "U24b.6" , "U24bonsonm.6" '...
         ' , "U25aonsofm.6" , "U25aoff.6" , "U25a.6" , "U25aonsonm.6" '...
         ' , "U25bonsofm.6" , "U25boff.6" , "U25b.6" , "U25bonsonm.6" '...
         ' , "U26aonsofm.6" , "U26aoff.6" , "U26a.6" , "U26aonsonm.6" '...
         ' , "U26bonsofm.6" , "U26boff.6" , "U26b.6" , "U26bonsonm.6" '...
         ' , "U27onsofm.6" , "U27off.6" , "U27.6" , "U27onsonm.6" '...
         ' , "U28onsofm.6" , "U28off.6" , "U28.6" , "U28onsonm.6" '...
         ' , "U29onsofm.6" , "U29off.6" , "U29.6" , "U29onsonm.6" '...
         ' , "U30onsofm.6" , "U30off.6" , "U30.6" , "U30onsonm.6" '...
         ' , "U31onsofm.6" , "U31off.6" , "U31.6" , "U31onsonm.6" '...
         ' , "U5off.6" , "U6off.6" , "U7off.6" , "U8off.6" , "U9off.6" , "U10off.6" , "U11off.6" , "U12off.6" '...
         ' , "U13off.6" , "U14off.6" , "U15off.6" , "U16off.6" , "U17off.6"  '...
         ' , "U32.6" , "U33.6" , "U34.6" , "U35.6" , "U36.6" '...
         ' , "U37.6" , "U38.6" , "U39.6" , "U40.6" , "U41.6" , "U42.6" '...
         ' , "HYoff.6" , "HYon.6" , "SEoff.6" , "SEon.6"  '...
         ];
      sqlquery2 = [sqlquery ...
         ' FROM Patients '...
         'WHERE Nom LIKE ''' nom '%'' '...
         'AND Prenom LIKE ''' prenom '%'' '...
         'AND Nom NOT LIKE ''%(suite)%'' '...
         ];
   case {'24'}
      sqlquery = [...
         'SELECT Nom , Prenom , Sexe '...
         ' , "Date de naissance" , "Duree d''evolution" , "Date d''intervention" '...
         ' , "Date Mois24"'...
         ' , "U1.24" , "U2.24" , "U3.24" , "U4.24" , "U5.24" , "U6.24" , "U7.24" , "U8.24" , "U9.24" , "U10.24" , "U11.24" , "U12.24" '...
         ' , "U13.24" , "U14.24" , "U15.24" , "U16.24" , "U17.24" '...
         ' , "U18onsofm.24" , "U18ofsofm.24" , "U18ofsonm.24" , "U18onsonm.24" '...
         ' , "U19onsofm.24" , "U19ofsofm.24" , "U19ofsonm.24" , "U19onsonm.24" '...
         ' , "U20aonsofm.24" , "U20aofsofm.24" , "U20aofsonm.24" , "U20aonsonm.24" '...
         ' , "U20bonsofm.24" , "U20bofsofm.24" , "U20bofsonm.24" , "U20bonsonm.24" '...
         ' , "U20consofm.24" , "U20cofsofm.24" , "U20cofsonm.24" , "U20consonm.24" '...
         ' , "U20donsofm.24" , "U20dofsofm.24" , "U20dofsonm.24" , "U20donsonm.24" '...
         ' , "U20eonsofm.24" , "U20eofsofm.24" , "U20eofsonm.24" , "U20eonsonm.24" '...
         ' , "U21aonsofm.24" , "U21aofsofm.24" , "U21aofsonm.24" , "U21aonsonm.24" '...
         ' , "U21bonsofm.24" , "U21bofsofm.24" , "U21bofsonm.24" , "U21bonsonm.24" '...
         ' , "U22aonsofm.24" , "U22aofsofm.24" , "U22aofsonm.24" , "U22aonsonm.24" '...
         ' , "U22bonsofm.24" , "U22bofsofm.24" , "U22bofsonm.24" , "U22bonsonm.24" '...
         ' , "U22consofm.24" , "U22cofsofm.24" , "U22cofsonm.24" , "U22consonm.24" '...
         ' , "U22donsofm.24" , "U22dofsofm.24" , "U22dofsonm.24" , "U22donsonm.24" '...
         ' , "U22eonsofm.24" , "U22eofsofm.24" , "U22eofsonm.24" , "U22eonsonm.24" '...
         ' , "U23aonsofm.24" , "U23aofsofm.24" , "U23aofsonm.24" , "U23aonsonm.24" '...
         ' , "U23bonsofm.24" , "U23bofsofm.24" , "U23bofsonm.24" , "U23bonsonm.24" '...
         ' , "U24aonsofm.24" , "U24aofsofm.24" , "U24aofsonm.24" , "U24aonsonm.24" '...
         ' , "U24bonsofm.24" , "U24bofsofm.24" , "U24bofsonm.24" , "U24bonsonm.24" '...
         ' , "U25aonsofm.24" , "U25aofsofm.24" , "U25aofsonm.24" , "U25aonsonm.24" '...
         ' , "U25bonsofm.24" , "U25bofsofm.24" , "U25bofsonm.24" , "U25bonsonm.24" '...
         ' , "U26aonsofm.24" , "U26aofsofm.24" , "U26aofsonm.24" , "U26aonsonm.24" '...
         ' , "U26bonsofm.24" , "U26bofsofm.24" , "U26bofsonm.24" , "U26bonsonm.24" '...
         ' , "U27onsofm.24" , "U27ofsofm.24" , "U27ofsonm.24" , "U27onsonm.24" '...
         ' , "U28onsofm.24" , "U28ofsofm.24" , "U28ofsonm.24" , "U28onsonm.24" '...
         ' , "U29onsofm.24" , "U29ofsofm.24" , "U29ofsonm.24" , "U29onsonm.24" '...
         ' , "U30onsofm.24" , "U30ofsofm.24" , "U30ofsonm.24" , "U30onsonm.24" '...
         ' , "U31onsofm.24" , "U31ofsofm.24" , "U31ofsonm.24" , "U31onsonm.24" '...
         ' , "U5off.24" , "U6off.24" , "U7off.24" , "U8off.24" , "U9off.24" , "U10off.24" , "U11off.24" , "U12off.24" '...
         ' , "U13off.24" , "U14off.24" , "U15off.24" , "U16off.24" , "U17off.24"  '...
         ' , "U32.24" , "U33.24" , "U34.24" , "U35.24" , "U36.24" '...
         ' , "U37.24" , "U38.24" , "U39.24" , "U40.24" , "U41.24" , "U42.24" '...
         ' , "HYoff.24" , "HYon.24" , "SEoff.24" , "SEon.24"  '...
         ];
      sqlquery2 = [sqlquery ...
         ' FROM Patients '...
         'WHERE Nom LIKE ''' nom '%'' '...
         'AND Prenom LIKE ''' prenom '%'' '...
         'AND Nom NOT LIKE ''%(suite)%'' '...
         ];
   case {'60'}
      sqlquery = [...
         'SELECT Nom , Prenom , Sexe '...
         ' , "Date de naissance" , "Duree d''evolution" , "Date d''intervention" '...
         ' , "Date Mois60"'...
         ' , "U1.60" , "U2.60" , "U3.60" , "U4.60" , "U5.60" , "U6.60" , "U7.60" , "U8.60" , "U9.60" , "U10.60" , "U11.60" , "U12.60" '...
         ' , "U13.60" , "U14.60" , "U15.60" , "U16.60" , "U17.60" '...
         ' , "U18onsofm.60" , "U18OFF.60" , "U18.60" , "U18onsonm.60" '...
         ' , "U19onsofm.60" , "U19OFF.60" , "U19.60" , "U19onsonm.60" '...
         ' , "U20aonsofm.60" , "U20aOFF.60" , "U20a.60" , "U20aonsonm.60" '...
         ' , "U20bonsofm.60" , "U20bOFF.60" , "U20b.60" , "U20bonsonm.60" '...
         ' , "U20consofm.60" , "U20cOFF.60" , "U20c.60" , "U20consonm.60" '...
         ' , "U20donsofm.60" , "U20dOFF.60" , "U20d.60" , "U20donsonm.60" '...
         ' , "U20eonsofm.60" , "U20eOFF.60" , "U20e.60" , "U20eonsonm.60" '...
         ' , "U21aonsofm.60" , "U21aOFF.60" , "U21a.60" , "U21aonsonm.60" '...
         ' , "U21bonsofm.60" , "U21bOFF.60" , "U21b.60" , "U21bonsonm.60" '...
         ' , "U22aonsofm.60" , "U22aOFF.60" , "U22a.60" , "U22aonsonm.60" '...
         ' , "U22bonsofm.60" , "U22bOFF.60" , "U22b.60" , "U22bonsonm.60" '...
         ' , "U22consofm.60" , "U22cOFF.60" , "U22c.60" , "U22consonm.60" '...
         ' , "U22donsofm.60" , "U22dOFF.60" , "U22d.60" , "U22donsonm.60" '...
         ' , "U22eonsofm.60" , "U22eOFF.60" , "U22e.60" , "U22eonsonm.60" '...
         ' , "U23aonsofm.60" , "U23aOFF.60" , "U23a.60" , "U23aonsonm.60" '...
         ' , "U23bonsofm.60" , "U23bOFF.60" , "U23b.60" , "U23bonsonm.60" '...
         ' , "U24aonsofm.60" , "U24aOFF.60" , "U24a.60" , "U24aonsonm.60" '...
         ' , "U24bonsofm.60" , "U24bOFF.60" , "U24b.60" , "U24bonsonm.60" '...
         ' , "U25aonsofm.60" , "U25aOFF.60" , "U25a.60" , "U25aonsonm.60" '...
         ' , "U25bonsofm.60" , "U25bOFF.60" , "U25b.60" , "U25bonsonm.60" '...
         ' , "U26aonsofm.60" , "U26aOFF.60" , "U26a.60" , "U26aonsonm.60" '...
         ' , "U26bonsofm.60" , "U26bOFF.60" , "U26b.60" , "U26bonsonm.60" '...
         ' , "U27onsofm.60" , "U27OFF.60" , "U27.60" , "U27onsonm.60" '...
         ' , "U28onsofm.60" , "U28OFF.60" , "U28.60" , "U28onsonm.60" '...
         ' , "U29onsofm.60" , "U29OFF.60" , "U29.60" , "U29onsonm.60" '...
         ' , "U30onsofm.60" , "U30OFF.60" , "U30.60" , "U30onsonm.60" '...
         ' , "U31onsofm.60" , "U31OFF.60" , "U31.60" , "U31onsonm.60" '...
         ' , "U5OFF.60" , "U6OFF.60" , "U7OFF.60" , "U8OFF.60" , "U9OFF.60" , "U10OFF.60" , "U11OFF.60" , "U12OFF.60" '...
         ' , "U13OFF.60" , "U14OFF.60" , "U15OFF.60" , "U16OFF.60" , "U17OFF.60"  '...
         ' , "U32.60" , "U33.60" , "U34.60" , "U35.60" , "U36.60" '...
         ' , "U37.60" , "U38.60" , "U39.60" , "U40.60" , "U41.60" , "U42.60" '...
         ' , "HYOFF.60" , "HY.60" , "SEOFF.60" , "SE.60"  '...
         ];
      sqlquery2 = [sqlquery ...
         ' FROM Patients '...
         'WHERE Nom LIKE ''' nom '%'' '...
         'AND Prenom LIKE ''' prenom '%'' '...
         'AND Nom NOT LIKE ''%(suite)%'' '...
         ];
   case {'120'}
      sqlquery = [...
         'SELECT Nom , Prenom , Sexe '...
         ' , "Date de naissance" , "Duree d''evolution" , "Date d''intervention" '...
         ' , "Date Mois6"'...
         ' , "U1.6" , "U2.6" , "U3.6" , "U4.6" , "U5.6" , "U6.6" , "U7.6" , "U8.6" , "U9.6" , "U10.6" , "U11.6" , "U12.6" '...
         ' , "U13.6" , "U14.6" , "U15.6" , "U16.6" , "U17.6" '...
         ' , "U18onsofm.6" , "U18off.6" , "U18.6" , "U18onsonm.6" '...
         ' , "U19onsofm.6" , "U19off.6" , "U19.6" , "U19onsonm.6" '...
         ' , "U20aonsofm.6" , "U20aoff.6" , "U20a.6" , "U20aonsonm.6" '...
         ' , "U20bonsofm.6" , "U20boff.6" , "U20b.6" , "U20bonsonm.6" '...
         ' , "U20consofm.6" , "U20coff.6" , "U20c.6" , "U20consonm.6" '...
         ' , "U20donsofm.6" , "U20doff.6" , "U20d.6" , "U20donsonm.6" '...
         ' , "U20eonsofm.6" , "U20eoff.6" , "U20e.6" , "U20eonsonm.6" '...
         ' , "U21aonsofm.6" , "U21aoff.6" , "U21a.6" , "U21aonsonm.6" '...
         ' , "U21bonsofm.6" , "U21boff.6" , "U21b.6" , "U21bonsonm.6" '...
         ' , "U22aonsofm.6" , "U22aoff.6" , "U22a.6" , "U22aonsonm.6" '...
         ' , "U22bonsofm.6" , "U22boff.6" , "U22b.6" , "U22bonsonm.6" '...
         ' , "U22consofm.6" , "U22coff.6" , "U22c.6" , "U22consonm.6" '...
         ' , "U22donsofm.6" , "U22doff.6" , "U22d.6" , "U22donsonm.6" '...
         ' , "U22eonsofm.6" , "U22eoff.6" , "U22e.6" , "U22eonsonm.6" '...
         ' , "U23aonsofm.6" , "U23aoff.6" , "U23a.6" , "U23aonsonm.6" '...
         ' , "U23bonsofm.6" , "U23boff.6" , "U23b.6" , "U23bonsonm.6" '...
         ' , "U24aonsofm.6" , "U24aoff.6" , "U24a.6" , "U24aonsonm.6" '...
         ' , "U24bonsofm.6" , "U24boff.6" , "U24b.6" , "U24bonsonm.6" '...
         ' , "U25aonsofm.6" , "U25aoff.6" , "U25a.6" , "U25aonsonm.6" '...
         ' , "U25bonsofm.6" , "U25boff.6" , "U25b.6" , "U25bonsonm.6" '...
         ' , "U26aonsofm.6" , "U26aoff.6" , "U26a.6" , "U26aonsonm.6" '...
         ' , "U26bonsofm.6" , "U26boff.6" , "U26b.6" , "U26bonsonm.6" '...
         ' , "U27onsofm.6" , "U27off.6" , "U27.6" , "U27onsonm.6" '...
         ' , "U28onsofm.6" , "U28off.6" , "U28.6" , "U28onsonm.6" '...
         ' , "U29onsofm.6" , "U29off.6" , "U29.6" , "U29onsonm.6" '...
         ' , "U30onsofm.6" , "U30off.6" , "U30.6" , "U30onsonm.6" '...
         ' , "U31onsofm.6" , "U31off.6" , "U31.6" , "U31onsonm.6" '...
         ' , "U5off.6" , "U6off.6" , "U7off.6" , "U8off.6" , "U9off.6" , "U10off.6" , "U11off.6" , "U12off.6" '...
         ' , "U13off.6" , "U14off.6" , "U15off.6" , "U16off.6" , "U17off.6"  '...
         ' , "U32.6" , "U33.6" , "U34.6" , "U35.6" , "U36.6" '...
         ' , "U37.6" , "U38.6" , "U39.6" , "U40.6" , "U41.6" , "U42.6" '...
         ' , "HYoff.6" , "HYon.6" , "SEoff.6" , "SEon.6"  '...
         ];
      sqlquery2 = [sqlquery ...
         ' FROM Patients '...
         'WHERE Nom LIKE ''' nom '%'' '...
         'AND Prenom LIKE ''' prenom '%'' '...
         'AND Nom LIKE ''%(suite)%'' '...
         ];
   otherwise
      error('Uknown exam type');
end

curs = exec(conn,sqlquery2);
curs = fetch(curs);
data = curs.Data;
close(conn);
clear curs conn;

if ~isstruct(data)
   if strcmp(data{1},'No Data')
      error('No data matching this PatientID');
   end
end

if numel(data.Nom) > 1
   q = linq(data.Nom);
   c =  q.select(@(x,y) {[x ', ' y]},data.Prenom).toList;
   s = listdlg('PromptString','Select a patient:','SelectionMode','single',...
                'ListString',c);
   [updrs,patient] = fetch_UPDRS({data.Nom{s} data.Prenom{s}},exam,ip);
   return;
   %error('ID does not specify unique DB entry');
end

updrs = UPDRS();
if iscell(id)
   updrs.name = [id{1}(1:min(3,numel(id{1}))) id{2}(1:min(2,numel(id{2})))];
else
   updrs.name = id;
end
updrs.url = url;
try
   switch lower(exam)
      case {'inclusion'}
         try
            updrs.date = datestr(datenum(data.DateBilanPreoperatoire,'yyyy-mm-dd'),updrs.dateFormat);
         catch
            updrs.date = '';
         end
         updrs.description = exam;
         updrs.item1 = data.U1;
         updrs.item2 = data.U2;
         updrs.item3 = data.U3;
         updrs.item4 = data.U4;
         updrs.item5.off = data.U5off;
         updrs.item5.on = data.U5;
         updrs.item6.off = data.U6off;
         updrs.item6.on = data.U6;
         updrs.item7.off = data.U7off;
         updrs.item7.on = data.U7;
         updrs.item8.off = data.U8off;
         updrs.item8.on = data.U8;
         updrs.item9.off = data.U9off;
         updrs.item9.on = data.U9;
         updrs.item10.off = data.U10off;
         updrs.item10.on = data.U10;
         updrs.item11.off = data.U11off;
         updrs.item11.on = data.U11;
         updrs.item12.off = data.U12off;
         updrs.item12.on = data.U12;
         updrs.item13.off = data.U13off;
         updrs.item13.on = data.U13;
         updrs.item14.off = data.U14off;
         updrs.item14.on = data.U14;
         updrs.item15.off = data.U15off;
         updrs.item15.on = data.U15;
         updrs.item16.off = data.U16off;
         updrs.item16.on = data.U16;
         updrs.item17.off = data.U17off;
         updrs.item17.on = data.U17;
         updrs.item18.offStim.offMed = data.U18off;
         updrs.item18.offStim.onMed = data.U18;
         updrs.item19.offStim.offMed = data.U19off;
         updrs.item19.offStim.onMed = data.U19;
         updrs.item20a.offStim.offMed = data.U20aoff;
         updrs.item20b.offStim.offMed = data.U20boff;
         updrs.item20c.offStim.offMed = data.U20coff;
         updrs.item20d.offStim.offMed = data.U20doff;
         updrs.item20e.offStim.offMed = data.U20eoff;
         updrs.item20a.offStim.onMed = data.U20a;
         updrs.item20b.offStim.onMed = data.U20b;
         updrs.item20c.offStim.onMed = data.U20c;
         updrs.item20d.offStim.onMed = data.U20d;
         updrs.item20e.offStim.onMed = data.U20e;
         updrs.item21a.offStim.offMed = data.U21aoff;
         updrs.item21b.offStim.offMed = data.U21boff;
         updrs.item21a.offStim.onMed = data.U21a;
         updrs.item21b.offStim.onMed = data.U21b;
         updrs.item22a.offStim.offMed = data.U22aoff;
         updrs.item22b.offStim.offMed = data.U22boff;
         updrs.item22c.offStim.offMed = data.U22coff;
         updrs.item22d.offStim.offMed = data.U22doff;
         updrs.item22e.offStim.offMed = data.U22eoff;
         updrs.item22a.offStim.onMed = data.U22a;
         updrs.item22b.offStim.onMed = data.U22b;
         updrs.item22c.offStim.onMed = data.U22c;
         updrs.item22d.offStim.onMed = data.U22d;
         updrs.item22e.offStim.onMed = data.U22e;
         updrs.item23a.offStim.offMed = data.U23aoff;
         updrs.item23b.offStim.offMed = data.U23boff;
         updrs.item23a.offStim.onMed = data.U23a;
         updrs.item23b.offStim.onMed = data.U23b;
         updrs.item24a.offStim.offMed = data.U24aoff;
         updrs.item24b.offStim.offMed = data.U24boff;
         updrs.item24a.offStim.onMed = data.U24a;
         updrs.item24b.offStim.onMed = data.U24b;
         updrs.item25a.offStim.offMed = data.U25aoff;
         updrs.item25b.offStim.offMed = data.U25boff;
         updrs.item25a.offStim.onMed = data.U25a;
         updrs.item25b.offStim.onMed = data.U25b;
         updrs.item26a.offStim.offMed = data.U26aoff;
         updrs.item26b.offStim.offMed = data.U26boff;
         updrs.item26a.offStim.onMed = data.U26a;
         updrs.item26b.offStim.onMed = data.U26b;
         updrs.item27.offStim.offMed = data.U27off;
         updrs.item27.offStim.onMed = data.U27;
         updrs.item28.offStim.offMed = data.U28off;
         updrs.item28.offStim.onMed = data.U28;
         updrs.item29.offStim.offMed = data.U29off;
         updrs.item29.offStim.onMed = data.U29;
         updrs.item30.offStim.offMed = data.U30off;
         updrs.item30.offStim.onMed = data.U30;
         updrs.item31.offStim.offMed = data.U31off;
         updrs.item31.offStim.onMed = data.U31;
         updrs.item32 = data.U32;
         updrs.item33 = data.U33;
         updrs.item34 = data.U34;
         updrs.item35 = data.U35;
         updrs.item36 = data.U36;
         updrs.item37 = data.U37;
         updrs.item38 = data.U38;
         updrs.item39 = data.U39;
         updrs.item40 = data.U40;
         updrs.item41 = data.U41;
         updrs.item42 = data.U42;
         updrs.HoehnYahr.off = data.H0x2EYoff;
         updrs.HoehnYahr.on = data.H0x2EYon;
         updrs.SchwabEngland.off = data.S0x2EEoff;
         updrs.SchwabEngland.on = data.S0x2EEon;
      case {'6','6-12','12','120'}
         try
            updrs.date = datestr(datenum(data.DateMois6,'yyyy-mm-dd'),updrs.dateFormat);
         catch
            updrs.date = '';
         end
         updrs.description = exam;
         updrs.item1 = data.U10x2E6;
         updrs.item2 = data.U20x2E6;
         updrs.item3 = data.U30x2E6;
         updrs.item4 = data.U40x2E6;
         updrs.item5.off = data.U5off0x2E6;
         updrs.item5.on = data.U50x2E6;
         updrs.item6.off = data.U6off0x2E6;
         updrs.item6.on = data.U60x2E6;
         updrs.item7.off = data.U7off0x2E6;
         updrs.item7.on = data.U70x2E6;
         updrs.item8.off = data.U8off0x2E6;
         updrs.item8.on = data.U80x2E6;
         updrs.item9.off = data.U9off0x2E6;
         updrs.item9.on = data.U90x2E6;
         updrs.item10.off = data.U10off0x2E6;
         updrs.item10.on = data.U100x2E6;
         updrs.item11.off = data.U11off0x2E6;
         updrs.item11.on = data.U110x2E6;
         updrs.item12.off = data.U12off0x2E6;
         updrs.item12.on = data.U120x2E6;
         updrs.item13.off = data.U13off0x2E6;
         updrs.item13.on = data.U130x2E6;
         updrs.item14.off = data.U14off0x2E6;
         updrs.item14.on = data.U140x2E6;
         updrs.item15.off = data.U15off0x2E6;
         updrs.item15.on = data.U150x2E6;
         updrs.item16.off = data.U16off0x2E6;
         updrs.item16.on = data.U160x2E6;
         updrs.item17.off = data.U17off0x2E6;
         updrs.item17.on = data.U170x2E6;
         updrs.item18.onStim.offMed = data.U18onsofm0x2E6;
         updrs.item18.offStim.offMed = data.U18off0x2E6;
         updrs.item18.offStim.onMed = data.U180x2E6;
         updrs.item18.onStim.onMed = data.U18onsonm0x2E6;
         updrs.item19.onStim.offMed = data.U19onsofm0x2E6;
         updrs.item19.offStim.offMed = data.U19off0x2E6;
         updrs.item19.offStim.onMed = data.U190x2E6;
         updrs.item19.onStim.onMed = data.U19onsonm0x2E6;
         updrs.item20a.onStim.offMed = data.U20aonsofm0x2E6;
         updrs.item20a.offStim.offMed = data.U20aoff0x2E6;
         updrs.item20a.offStim.onMed = data.U20a0x2E6;
         updrs.item20a.onStim.onMed = data.U20aonsonm0x2E6;
         updrs.item20b.onStim.offMed = data.U20bonsofm0x2E6;
         updrs.item20b.offStim.offMed = data.U20boff0x2E6;
         updrs.item20b.offStim.onMed = data.U20b0x2E6;
         updrs.item20b.onStim.onMed = data.U20bonsonm0x2E6;
         updrs.item20c.onStim.offMed = data.U20consofm0x2E6;
         updrs.item20c.offStim.offMed = data.U20coff0x2E6;
         updrs.item20c.offStim.onMed = data.U20c0x2E6;
         updrs.item20c.onStim.onMed = data.U20consonm0x2E6;
         updrs.item20d.onStim.offMed = data.U20donsofm0x2E6;
         updrs.item20d.offStim.offMed = data.U20doff0x2E6;
         updrs.item20d.offStim.onMed = data.U20d0x2E6;
         updrs.item20d.onStim.onMed = data.U20donsonm0x2E6;
         updrs.item20e.onStim.offMed = data.U20eonsofm0x2E6;
         updrs.item20e.offStim.offMed = data.U20eoff0x2E6;
         updrs.item20e.offStim.onMed = data.U20e0x2E6;
         updrs.item20e.onStim.onMed = data.U20eonsonm0x2E6;
         updrs.item21a.onStim.offMed = data.U21aonsofm0x2E6;
         updrs.item21a.offStim.offMed = data.U21aoff0x2E6;
         updrs.item21a.offStim.onMed = data.U21a0x2E6;
         updrs.item21a.onStim.onMed = data.U21aonsonm0x2E6;
         updrs.item21b.onStim.offMed = data.U21bonsofm0x2E6;
         updrs.item21b.offStim.offMed = data.U21boff0x2E6;
         updrs.item21b.offStim.onMed = data.U21b0x2E6;
         updrs.item21b.onStim.onMed = data.U21bonsonm0x2E6;
         updrs.item22a.onStim.offMed = data.U22aonsofm0x2E6;
         updrs.item22a.offStim.offMed = data.U22aoff0x2E6;
         updrs.item22a.offStim.onMed = data.U22a0x2E6;
         updrs.item22a.onStim.onMed = data.U22aonsonm0x2E6;
         updrs.item22b.onStim.offMed = data.U22bonsofm0x2E6;
         updrs.item22b.offStim.offMed = data.U22boff0x2E6;
         updrs.item22b.offStim.onMed = data.U22b0x2E6;
         updrs.item22b.onStim.onMed = data.U22bonsonm0x2E6;
         updrs.item22c.onStim.offMed = data.U22consofm0x2E6;
         updrs.item22c.offStim.offMed = data.U22coff0x2E6;
         updrs.item22c.offStim.onMed = data.U22c0x2E6;
         updrs.item22c.onStim.onMed = data.U22consonm0x2E6;
         updrs.item22d.onStim.offMed = data.U22donsofm0x2E6;
         updrs.item22d.offStim.offMed = data.U22doff0x2E6;
         updrs.item22d.offStim.onMed = data.U22d0x2E6;
         updrs.item22d.onStim.onMed = data.U22donsonm0x2E6;
         updrs.item22e.onStim.offMed = data.U22eonsofm0x2E6;
         updrs.item22e.offStim.offMed = data.U22eoff0x2E6;
         updrs.item22e.offStim.onMed = data.U22e0x2E6;
         updrs.item22e.onStim.onMed = data.U22eonsonm0x2E6;
         updrs.item23a.onStim.offMed = data.U23aonsofm0x2E6;
         updrs.item23a.offStim.offMed = data.U23aoff0x2E6;
         updrs.item23a.offStim.onMed = data.U23a0x2E6;
         updrs.item23a.onStim.onMed = data.U23aonsonm0x2E6;
         updrs.item23b.onStim.offMed = data.U23bonsofm0x2E6;
         updrs.item23b.offStim.offMed = data.U23boff0x2E6;
         updrs.item23b.offStim.onMed = data.U23b0x2E6;
         updrs.item23b.onStim.onMed = data.U23bonsonm0x2E6;
         updrs.item24a.onStim.offMed = data.U24aonsofm0x2E6;
         updrs.item24a.offStim.offMed = data.U24aoff0x2E6;
         updrs.item24a.offStim.onMed = data.U24a0x2E6;
         updrs.item24a.onStim.onMed = data.U24aonsonm0x2E6;
         updrs.item24b.onStim.offMed = data.U24bonsofm0x2E6;
         updrs.item24b.offStim.offMed = data.U24boff0x2E6;
         updrs.item24b.offStim.onMed = data.U24b0x2E6;
         updrs.item24b.onStim.onMed = data.U24bonsonm0x2E6;
         updrs.item25a.onStim.offMed = data.U25aonsofm0x2E6;
         updrs.item25a.offStim.offMed = data.U25aoff0x2E6;
         updrs.item25a.offStim.onMed = data.U25a0x2E6;
         updrs.item25a.onStim.onMed = data.U25aonsonm0x2E6;
         updrs.item25b.onStim.offMed = data.U25bonsofm0x2E6;
         updrs.item25b.offStim.offMed = data.U25boff0x2E6;
         updrs.item25b.offStim.onMed = data.U25b0x2E6;
         updrs.item25b.onStim.onMed = data.U25bonsonm0x2E6;
         updrs.item26a.onStim.offMed = data.U26aonsofm0x2E6;
         updrs.item26a.offStim.offMed = data.U26aoff0x2E6;
         updrs.item26a.offStim.onMed = data.U26a0x2E6;
         updrs.item26a.onStim.onMed = data.U26aonsonm0x2E6;
         updrs.item26b.onStim.offMed = data.U26bonsofm0x2E6;
         updrs.item26b.offStim.offMed = data.U26boff0x2E6;
         updrs.item26b.offStim.onMed = data.U26b0x2E6;
         updrs.item26b.onStim.onMed = data.U26bonsonm0x2E6;
         updrs.item27.onStim.offMed = data.U27onsofm0x2E6;
         updrs.item27.offStim.offMed = data.U27off0x2E6;
         updrs.item27.offStim.onMed = data.U270x2E6;
         updrs.item27.onStim.onMed = data.U27onsonm0x2E6;
         updrs.item28.onStim.offMed = data.U28onsofm0x2E6;
         updrs.item28.offStim.offMed = data.U28off0x2E6;
         updrs.item28.offStim.onMed = data.U280x2E6;
         updrs.item28.onStim.onMed = data.U28onsonm0x2E6;
         updrs.item29.onStim.offMed = data.U29onsofm0x2E6;
         updrs.item29.offStim.offMed = data.U29off0x2E6;
         updrs.item29.offStim.onMed = data.U290x2E6;
         updrs.item29.onStim.onMed = data.U29onsonm0x2E6;
         updrs.item30.onStim.offMed = data.U30onsofm0x2E6;
         updrs.item30.offStim.offMed = data.U30off0x2E6;
         updrs.item30.offStim.onMed = data.U300x2E6;
         updrs.item30.onStim.onMed = data.U30onsonm0x2E6;
         updrs.item31.onStim.offMed = data.U31onsofm0x2E6;
         updrs.item31.offStim.offMed = data.U31off0x2E6;
         updrs.item31.offStim.onMed = data.U310x2E6;
         updrs.item31.onStim.onMed = data.U31onsonm0x2E6;
         updrs.item32 = data.U320x2E6;
         updrs.item33 = data.U330x2E6;
         updrs.item34 = data.U340x2E6;
         updrs.item35 = data.U350x2E6;
         updrs.item36 = data.U360x2E6;
         updrs.item37 = data.U370x2E6;
         updrs.item38 = data.U380x2E6;
         updrs.item39 = data.U390x2E6;
         updrs.item40 = data.U400x2E6;
         updrs.item41 = data.U410x2E6;
         updrs.item42 = data.U420x2E6;
         updrs.HoehnYahr.off = data.HYoff0x2E6;
         updrs.HoehnYahr.on = data.HYon0x2E6;
         updrs.SchwabEngland.off = data.SEoff0x2E6;
         updrs.SchwabEngland.on = data.SEon0x2E6;
      case {'24'}
         try
            updrs.date = datestr(datenum(data.DateMois24,'yyyy-mm-dd'),updrs.dateFormat);
         catch
            updrs.date = '';
         end
         updrs.description = exam;
         updrs.item1 = data.U10x2E24;
         updrs.item2 = data.U20x2E24;
         updrs.item3 = data.U30x2E24;
         updrs.item4 = data.U40x2E24;
         updrs.item5.off = data.U5off0x2E24;
         updrs.item5.on = data.U50x2E24;
         updrs.item6.off = data.U6off0x2E24;
         updrs.item6.on = data.U60x2E24;
         updrs.item7.off = data.U7off0x2E24;
         updrs.item7.on = data.U70x2E24;
         updrs.item8.off = data.U8off0x2E24;
         updrs.item8.on = data.U80x2E24;
         updrs.item9.off = data.U9off0x2E24;
         updrs.item9.on = data.U90x2E24;
         updrs.item10.off = data.U10off0x2E24;
         updrs.item10.on = data.U100x2E24;
         updrs.item11.off = data.U11off0x2E24;
         updrs.item11.on = data.U110x2E24;
         updrs.item12.off = data.U12off0x2E24;
         updrs.item12.on = data.U120x2E24;
         updrs.item13.off = data.U13off0x2E24;
         updrs.item13.on = data.U130x2E24;
         updrs.item14.off = data.U14off0x2E24;
         updrs.item14.on = data.U140x2E24;
         updrs.item15.off = data.U15off0x2E24;
         updrs.item15.on = data.U150x2E24;
         updrs.item16.off = data.U16off0x2E24;
         updrs.item16.on = data.U160x2E24;
         updrs.item17.off = data.U17off0x2E24;
         updrs.item17.on = data.U170x2E24;
         updrs.item18.onStim.offMed = data.U18onsofm0x2E24;
         updrs.item18.offStim.offMed = data.U18ofsofm0x2E24;
         updrs.item18.offStim.onMed = data.U18ofsonm0x2E24;
         updrs.item18.onStim.onMed = data.U18onsonm0x2E24;
         updrs.item19.onStim.offMed = data.U19onsofm0x2E24;
         updrs.item19.offStim.offMed = data.U19ofsofm0x2E24;
         updrs.item19.offStim.onMed = data.U19ofsonm0x2E24;
         updrs.item19.onStim.onMed = data.U19onsonm0x2E24;
         updrs.item20a.onStim.offMed = data.U20aonsofm0x2E24;
         updrs.item20a.offStim.offMed = data.U20aofsofm0x2E24;
         updrs.item20a.offStim.onMed = data.U20aofsonm0x2E24;
         updrs.item20a.onStim.onMed = data.U20aonsonm0x2E24;
         updrs.item20b.onStim.offMed = data.U20bonsofm0x2E24;
         updrs.item20b.offStim.offMed = data.U20bofsofm0x2E24;
         updrs.item20b.offStim.onMed = data.U20bofsonm0x2E24;
         updrs.item20b.onStim.onMed = data.U20bonsonm0x2E24;
         updrs.item20c.onStim.offMed = data.U20consofm0x2E24;
         updrs.item20c.offStim.offMed = data.U20cofsofm0x2E24;
         updrs.item20c.offStim.onMed = data.U20cofsonm0x2E24;
         updrs.item20c.onStim.onMed = data.U20consonm0x2E24;
         updrs.item20d.onStim.offMed = data.U20donsofm0x2E24;
         updrs.item20d.offStim.offMed = data.U20dofsofm0x2E24;
         updrs.item20d.offStim.onMed = data.U20dofsonm0x2E24;
         updrs.item20d.onStim.onMed = data.U20donsonm0x2E24;
         updrs.item20e.onStim.offMed = data.U20eonsofm0x2E24;
         updrs.item20e.offStim.offMed = data.U20eofsofm0x2E24;
         updrs.item20e.offStim.onMed = data.U20eofsonm0x2E24;
         updrs.item20e.onStim.onMed = data.U20eonsonm0x2E24;
         updrs.item21a.onStim.offMed = data.U21aonsofm0x2E24;
         updrs.item21a.offStim.offMed = data.U21aofsofm0x2E24;
         updrs.item21a.offStim.onMed = data.U21aofsonm0x2E24;
         updrs.item21a.onStim.onMed = data.U21aonsonm0x2E24;
         updrs.item21b.onStim.offMed = data.U21bonsofm0x2E24;
         updrs.item21b.offStim.offMed = data.U21bofsofm0x2E24;
         updrs.item21b.offStim.onMed = data.U21bofsonm0x2E24;
         updrs.item21b.onStim.onMed = data.U21bonsonm0x2E24;
         updrs.item22a.onStim.offMed = data.U22aonsofm0x2E24;
         updrs.item22a.offStim.offMed = data.U22aofsofm0x2E24;
         updrs.item22a.offStim.onMed = data.U22aofsonm0x2E24;
         updrs.item22a.onStim.onMed = data.U22aonsonm0x2E24;
         updrs.item22b.onStim.offMed = data.U22bonsofm0x2E24;
         updrs.item22b.offStim.offMed = data.U22bofsofm0x2E24;
         updrs.item22b.offStim.onMed = data.U22bofsonm0x2E24;
         updrs.item22b.onStim.onMed = data.U22bonsonm0x2E24;
         updrs.item22c.onStim.offMed = data.U22consofm0x2E24;
         updrs.item22c.offStim.offMed = data.U22cofsofm0x2E24;
         updrs.item22c.offStim.onMed = data.U22cofsonm0x2E24;
         updrs.item22c.onStim.onMed = data.U22consonm0x2E24;
         updrs.item22d.onStim.offMed = data.U22donsofm0x2E24;
         updrs.item22d.offStim.offMed = data.U22dofsofm0x2E24;
         updrs.item22d.offStim.onMed = data.U22dofsonm0x2E24;
         updrs.item22d.onStim.onMed = data.U22donsonm0x2E24;
         updrs.item22e.onStim.offMed = data.U22eonsofm0x2E24;
         updrs.item22e.offStim.offMed = data.U22eofsofm0x2E24;
         updrs.item22e.offStim.onMed = data.U22eofsonm0x2E24;
         updrs.item22e.onStim.onMed = data.U22eonsonm0x2E24;
         updrs.item23a.onStim.offMed = data.U23aonsofm0x2E24;
         updrs.item23a.offStim.offMed = data.U23aofsofm0x2E24;
         updrs.item23a.offStim.onMed = data.U23aofsonm0x2E24;
         updrs.item23a.onStim.onMed = data.U23aonsonm0x2E24;
         updrs.item23b.onStim.offMed = data.U23bonsofm0x2E24;
         updrs.item23b.offStim.offMed = data.U23bofsofm0x2E24;
         updrs.item23b.offStim.onMed = data.U23bofsonm0x2E24;
         updrs.item23b.onStim.onMed = data.U23bonsonm0x2E24;
         updrs.item24a.onStim.offMed = data.U24aonsofm0x2E24;
         updrs.item24a.offStim.offMed = data.U24aofsofm0x2E24;
         updrs.item24a.offStim.onMed = data.U24aofsonm0x2E24;
         updrs.item24a.onStim.onMed = data.U24aonsonm0x2E24;
         updrs.item24b.onStim.offMed = data.U24bonsofm0x2E24;
         updrs.item24b.offStim.offMed = data.U24bofsofm0x2E24;
         updrs.item24b.offStim.onMed = data.U24bofsonm0x2E24;
         updrs.item24b.onStim.onMed = data.U24bonsonm0x2E24;
         updrs.item25a.onStim.offMed = data.U25aonsofm0x2E24;
         updrs.item25a.offStim.offMed = data.U25aofsofm0x2E24;
         updrs.item25a.offStim.onMed = data.U25aofsonm0x2E24;
         updrs.item25a.onStim.onMed = data.U25aonsonm0x2E24;
         updrs.item25b.onStim.offMed = data.U25bonsofm0x2E24;
         updrs.item25b.offStim.offMed = data.U25bofsofm0x2E24;
         updrs.item25b.offStim.onMed = data.U25bofsonm0x2E24;
         updrs.item25b.onStim.onMed = data.U25bonsonm0x2E24;
         updrs.item26a.onStim.offMed = data.U26aonsofm0x2E24;
         updrs.item26a.offStim.offMed = data.U26aofsofm0x2E24;
         updrs.item26a.offStim.onMed = data.U26aofsonm0x2E24;
         updrs.item26a.onStim.onMed = data.U26aonsonm0x2E24;
         updrs.item26b.onStim.offMed = data.U26bonsofm0x2E24;
         updrs.item26b.offStim.offMed = data.U26bofsofm0x2E24;
         updrs.item26b.offStim.onMed = data.U26bofsonm0x2E24;
         updrs.item26b.onStim.onMed = data.U26bonsonm0x2E24;
         updrs.item27.onStim.offMed = data.U27onsofm0x2E24;
         updrs.item27.offStim.offMed = data.U27ofsofm0x2E24;
         updrs.item27.offStim.onMed = data.U27ofsonm0x2E24;
         updrs.item27.onStim.onMed = data.U27onsonm0x2E24;
         updrs.item28.onStim.offMed = data.U28onsofm0x2E24;
         updrs.item28.offStim.offMed = data.U28ofsofm0x2E24;
         updrs.item28.offStim.onMed = data.U28ofsonm0x2E24;
         updrs.item28.onStim.onMed = data.U28onsonm0x2E24;
         updrs.item29.onStim.offMed = data.U29onsofm0x2E24;
         updrs.item29.offStim.offMed = data.U29ofsofm0x2E24;
         updrs.item29.offStim.onMed = data.U29ofsonm0x2E24;
         updrs.item29.onStim.onMed = data.U29onsonm0x2E24;
         updrs.item30.onStim.offMed = data.U30onsofm0x2E24;
         updrs.item30.offStim.offMed = data.U30ofsofm0x2E24;
         updrs.item30.offStim.onMed = data.U30ofsonm0x2E24;
         updrs.item30.onStim.onMed = data.U30onsonm0x2E24;
         updrs.item31.onStim.offMed = data.U31onsofm0x2E24;
         updrs.item31.offStim.offMed = data.U31ofsofm0x2E24;
         updrs.item31.offStim.onMed = data.U31ofsonm0x2E24;
         updrs.item31.onStim.onMed = data.U31onsonm0x2E24;
         updrs.item32 = data.U320x2E24;
         updrs.item33 = data.U330x2E24;
         updrs.item34 = data.U340x2E24;
         updrs.item35 = data.U350x2E24;
         updrs.item36 = data.U360x2E24;
         updrs.item37 = data.U370x2E24;
         updrs.item38 = data.U380x2E24;
         updrs.item39 = data.U390x2E24;
         updrs.item40 = data.U400x2E24;
         updrs.item41 = data.U410x2E24;
         updrs.item42 = data.U420x2E24;
         updrs.HoehnYahr.off = data.HYoff0x2E24;
         updrs.HoehnYahr.on = data.HYon0x2E24;
         updrs.SchwabEngland.off = data.SEoff0x2E24;
         updrs.SchwabEngland.on = data.SEon0x2E24;
      case {'60'}
         try
            updrs.date = datestr(datenum(data.DateMois60,'yyyy-mm-dd'),updrs.dateFormat);
         catch
            updrs.date = '';
         end
         updrs.description = exam;
         updrs.item1 = data.U10x2E60;
         updrs.item2 = data.U20x2E60;
         updrs.item3 = data.U30x2E60;
         updrs.item4 = data.U40x2E60;
         updrs.item5.off = data.U5OFF0x2E60;
         updrs.item5.on = data.U50x2E60;
         updrs.item6.off = data.U6OFF0x2E60;
         updrs.item6.on = data.U60x2E60;
         updrs.item7.off = data.U7OFF0x2E60;
         updrs.item7.on = data.U70x2E60;
         updrs.item8.off = data.U8OFF0x2E60;
         updrs.item8.on = data.U80x2E60;
         updrs.item9.off = data.U9OFF0x2E60;
         updrs.item9.on = data.U90x2E60;
         updrs.item10.off = data.U10OFF0x2E60;
         updrs.item10.on = data.U100x2E60;
         updrs.item11.off = data.U11OFF0x2E60;
         updrs.item11.on = data.U110x2E60;
         updrs.item12.off = data.U12OFF0x2E60;
         updrs.item12.on = data.U120x2E60;
         updrs.item13.off = data.U13OFF0x2E60;
         updrs.item13.on = data.U130x2E60;
         updrs.item14.off = data.U14OFF0x2E60;
         updrs.item14.on = data.U140x2E60;
         updrs.item15.off = data.U15OFF0x2E60;
         updrs.item15.on = data.U150x2E60;
         updrs.item16.off = data.U16OFF0x2E60;
         updrs.item16.on = data.U160x2E60;
         updrs.item17.off = data.U17OFF0x2E60;
         updrs.item17.on = data.U170x2E60;
         updrs.item18.onStim.offMed = data.U18onsofm0x2E60;
         updrs.item18.offStim.offMed = data.U18OFF0x2E60;
         updrs.item18.offStim.onMed = data.U180x2E60;
         updrs.item18.onStim.onMed = data.U18onsonm0x2E60;
         updrs.item19.onStim.offMed = data.U19onsofm0x2E60;
         updrs.item19.offStim.offMed = data.U19OFF0x2E60;
         updrs.item19.offStim.onMed = data.U190x2E60;
         updrs.item19.onStim.onMed = data.U19onsonm0x2E60;
         updrs.item20a.onStim.offMed = data.U20aonsofm0x2E60;
         updrs.item20a.offStim.offMed = data.U20aOFF0x2E60;
         updrs.item20a.offStim.onMed = data.U20a0x2E60;
         updrs.item20a.onStim.onMed = data.U20aonsonm0x2E60;
         updrs.item20b.onStim.offMed = data.U20bonsofm0x2E60;
         updrs.item20b.offStim.offMed = data.U20bOFF0x2E60;
         updrs.item20b.offStim.onMed = data.U20b0x2E60;
         updrs.item20b.onStim.onMed = data.U20bonsonm0x2E60;
         updrs.item20c.onStim.offMed = data.U20consofm0x2E60;
         updrs.item20c.offStim.offMed = data.U20cOFF0x2E60;
         updrs.item20c.offStim.onMed = data.U20c0x2E60;
         updrs.item20c.onStim.onMed = data.U20consonm0x2E60;
         updrs.item20d.onStim.offMed = data.U20donsofm0x2E60;
         updrs.item20d.offStim.offMed = data.U20dOFF0x2E60;
         updrs.item20d.offStim.onMed = data.U20d0x2E60;
         updrs.item20d.onStim.onMed = data.U20donsonm0x2E60;
         updrs.item20e.onStim.offMed = data.U20eonsofm0x2E60;
         updrs.item20e.offStim.offMed = data.U20eOFF0x2E60;
         updrs.item20e.offStim.onMed = data.U20e0x2E60;
         updrs.item20e.onStim.onMed = data.U20eonsonm0x2E60;
         updrs.item21a.onStim.offMed = data.U21aonsofm0x2E60;
         updrs.item21a.offStim.offMed = data.U21aOFF0x2E60;
         updrs.item21a.offStim.onMed = data.U21a0x2E60;
         updrs.item21a.onStim.onMed = data.U21aonsonm0x2E60;
         updrs.item21b.onStim.offMed = data.U21bonsofm0x2E60;
         updrs.item21b.offStim.offMed = data.U21bOFF0x2E60;
         updrs.item21b.offStim.onMed = data.U21b0x2E60;
         updrs.item21b.onStim.onMed = data.U21bonsonm0x2E60;
         updrs.item22a.onStim.offMed = data.U22aonsofm0x2E60;
         updrs.item22a.offStim.offMed = data.U22aOFF0x2E60;
         updrs.item22a.offStim.onMed = data.U22a0x2E60;
         updrs.item22a.onStim.onMed = data.U22aonsonm0x2E60;
         updrs.item22b.onStim.offMed = data.U22bonsofm0x2E60;
         updrs.item22b.offStim.offMed = data.U22bOFF0x2E60;
         updrs.item22b.offStim.onMed = data.U22b0x2E60;
         updrs.item22b.onStim.onMed = data.U22bonsonm0x2E60;
         updrs.item22c.onStim.offMed = data.U22consofm0x2E60;
         updrs.item22c.offStim.offMed = data.U22cOFF0x2E60;
         updrs.item22c.offStim.onMed = data.U22c0x2E60;
         updrs.item22c.onStim.onMed = data.U22consonm0x2E60;
         updrs.item22d.onStim.offMed = data.U22donsofm0x2E60;
         updrs.item22d.offStim.offMed = data.U22dOFF0x2E60;
         updrs.item22d.offStim.onMed = data.U22d0x2E60;
         updrs.item22d.onStim.onMed = data.U22donsonm0x2E60;
         updrs.item22e.onStim.offMed = data.U22eonsofm0x2E60;
         updrs.item22e.offStim.offMed = data.U22eOFF0x2E60;
         updrs.item22e.offStim.onMed = data.U22e0x2E60;
         updrs.item22e.onStim.onMed = data.U22eonsonm0x2E60;
         updrs.item23a.onStim.offMed = data.U23aonsofm0x2E60;
         updrs.item23a.offStim.offMed = data.U23aOFF0x2E60;
         updrs.item23a.offStim.onMed = data.U23a0x2E60;
         updrs.item23a.onStim.onMed = data.U23aonsonm0x2E60;
         updrs.item23b.onStim.offMed = data.U23bonsofm0x2E60;
         updrs.item23b.offStim.offMed = data.U23bOFF0x2E60;
         updrs.item23b.offStim.onMed = data.U23b0x2E60;
         updrs.item23b.onStim.onMed = data.U23bonsonm0x2E60;
         updrs.item24a.onStim.offMed = data.U24aonsofm0x2E60;
         updrs.item24a.offStim.offMed = data.U24aOFF0x2E60;
         updrs.item24a.offStim.onMed = data.U24a0x2E60;
         updrs.item24a.onStim.onMed = data.U24aonsonm0x2E60;
         updrs.item24b.onStim.offMed = data.U24bonsofm0x2E60;
         updrs.item24b.offStim.offMed = data.U24bOFF0x2E60;
         updrs.item24b.offStim.onMed = data.U24b0x2E60;
         updrs.item24b.onStim.onMed = data.U24bonsonm0x2E60;
         updrs.item25a.onStim.offMed = data.U25aonsofm0x2E60;
         updrs.item25a.offStim.offMed = data.U25aOFF0x2E60;
         updrs.item25a.offStim.onMed = data.U25a0x2E60;
         updrs.item25a.onStim.onMed = data.U25aonsonm0x2E60;
         updrs.item25b.onStim.offMed = data.U25bonsofm0x2E60;
         updrs.item25b.offStim.offMed = data.U25bOFF0x2E60;
         updrs.item25b.offStim.onMed = data.U25b0x2E60;
         updrs.item25b.onStim.onMed = data.U25bonsonm0x2E60;
         updrs.item26a.onStim.offMed = data.U26aonsofm0x2E60;
         updrs.item26a.offStim.offMed = data.U26aOFF0x2E60;
         updrs.item26a.offStim.onMed = data.U26a0x2E60;
         updrs.item26a.onStim.onMed = data.U26aonsonm0x2E60;
         updrs.item26b.onStim.offMed = data.U26bonsofm0x2E60;
         updrs.item26b.offStim.offMed = data.U26bOFF0x2E60;
         updrs.item26b.offStim.onMed = data.U26b0x2E60;
         updrs.item26b.onStim.onMed = data.U26bonsonm0x2E60;
         updrs.item27.onStim.offMed = data.U27onsofm0x2E60;
         updrs.item27.offStim.offMed = data.U27OFF0x2E60;
         updrs.item27.offStim.onMed = data.U270x2E60;
         updrs.item27.onStim.onMed = data.U27onsonm0x2E60;
         updrs.item28.onStim.offMed = data.U28onsofm0x2E60;
         updrs.item28.offStim.offMed = data.U28OFF0x2E60;
         updrs.item28.offStim.onMed = data.U280x2E60;
         updrs.item28.onStim.onMed = data.U28onsonm0x2E60;
         updrs.item29.onStim.offMed = data.U29onsofm0x2E60;
         updrs.item29.offStim.offMed = data.U29OFF0x2E60;
         updrs.item29.offStim.onMed = data.U290x2E60;
         updrs.item29.onStim.onMed = data.U29onsonm0x2E60;
         updrs.item30.onStim.offMed = data.U30onsofm0x2E60;
         updrs.item30.offStim.offMed = data.U30OFF0x2E60;
         updrs.item30.offStim.onMed = data.U300x2E60;
         updrs.item30.onStim.onMed = data.U30onsonm0x2E60;
         updrs.item31.onStim.offMed = data.U31onsofm0x2E60;
         updrs.item31.offStim.offMed = data.U31OFF0x2E60;
         updrs.item31.offStim.onMed = data.U310x2E60;
         updrs.item31.onStim.onMed = data.U31onsonm0x2E60;
         updrs.item32 = data.U320x2E60;
         updrs.item33 = data.U330x2E60;
         updrs.item34 = data.U340x2E60;
         updrs.item35 = data.U350x2E60;
         updrs.item36 = data.U360x2E60;
         updrs.item37 = data.U370x2E60;
         updrs.item38 = data.U380x2E60;
         updrs.item39 = data.U390x2E60;
         updrs.item40 = data.U400x2E60;
         updrs.item41 = data.U410x2E60;
         updrs.item42 = data.U420x2E60;
         updrs.HoehnYahr.off = data.HYOFF0x2E60;
         updrs.HoehnYahr.on = data.HY0x2E60;
         updrs.SchwabEngland.off = data.SEOFF0x2E60;
         updrs.SchwabEngland.on = data.SE0x2E60;
      otherwise
   end
catch
end

if nargout == 2
   % patient metadata
   patient = metadata.Patient();
   patient.id = id;
   patient.exam = updrs;
   patient.dateOfBirth = data.DateDeNaissance;
end