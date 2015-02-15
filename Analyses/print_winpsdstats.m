batch_winpsdstats;

rigRoff = cat(1,info.RIGIDITY_OFF_R);
rigLoff = cat(1,info.RIGIDITY_OFF_L);
rigRon = cat(1,info.RIGIDITY_ON_R);
rigLon = cat(1,info.RIGIDITY_ON_L);
prL = 100*(rigLoff-rigLon)./rigLoff;
prR = 100*(rigRoff-rigRon)./rigRoff;

brRoff = cat(1,info.BRADYKINESIA_OFF_R);
brLoff = cat(1,info.BRADYKINESIA_OFF_L);
brRon = cat(1,info.BRADYKINESIA_ON_R);
brLon = cat(1,info.BRADYKINESIA_ON_L);
pbL = 100*(brLoff-brLon)./brLoff;
pbR = 100*(brRoff-brRon)./brRoff;


brrRoff = brRoff + rigRoff;
brrLoff = brLoff + rigLoff;
brrRon = brRon + rigRon;
brrLon = brLon + rigLon;
pbrrL = 100*(brrLoff-brrLon)./brrLoff;
pbrrR = 100*(brrRoff-brrRon)./brrRoff;

conditions = {'OFF' 'ON'};
tasks = {'BASELINEASSIS' 'BASELINEDEBOUT' 'REACH' 'MSUP'};
%tasks = {'BASELINEASSIS' 'BASELINEDEBOUT'};

f_range = 4:1:40;

%fid = 1;
fid = fopen('test.txt','w+');
for f = 1:numel(f_range)
   fprintf(fid,'f%g,',f_range(f));
end
fprintf(fid,'PATIENTID,TASK,CONDITION,SIDE,CHANNEL,UPDRS_OFF,UPDRS_ON');
fprintf(fid,'\n')

for i = 1:numel(info)
   for j = 1:numel(tasks)
      for k = 1:numel(conditions)
         if ~isempty(m(i,j,k).f) && ~isnan(info(i).UPDRSIII_OFF)
            for c = 1:3
               
               % LEFT
               if ~isnan(m(i,j,k).L_power(1,1)) % This will skip entire side
                  for f = 1:numel(f_range)
                     ind = m(i,j,k).f == f_range(f);
                     fprintf(fid,'%1.3f,',m(i,j,k).L_power(ind,c));
                  end
                  fprintf(fid,'%s,%s,%s,%s,%g,%1.3f,%1.3f\n',...
                     info(i).PATIENTID,tasks{j},conditions{k},'L',c,brrRoff(i),brrLoff(i));
               end
               
               % RIGHT
               if ~isnan(m(i,j,k).R_power(1,1))
                  for f = 1:numel(f_range)
                     ind = m(i,j,k).f == f_range(f);
                     fprintf(fid,'%1.3f,',m(i,j,k).R_power(ind,c));
                  end
                  fprintf(fid,'%s,%s,%s,%s,%g,%1.3f,%1.3f\n',...
                     info(i).PATIENTID,tasks{j},conditions{k},'R',c,brrRoff(i),brrLoff(i));
               end
            end
         end
      end
   end
end
