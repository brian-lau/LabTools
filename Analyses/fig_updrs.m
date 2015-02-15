

updrsoff = cat(1,info.UPDRSIII_OFF);
updrson = cat(1,info.UPDRSIII_ON);
pupdrs = 100*(updrsoff-updrson)./updrsoff;

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

[pLavg,pRavg,pLbrown,pRbrown] = getPower(m,1);

figure(1); hold on
xlabel('Beta band power change (% re off)')
ylabel('UPDRS change total (%)')
title('Brown method');
x = [pLbrown;pLbrown];
y = [pupdrs;pupdrs];
ind = isnan(x)|isnan(y);
x = x(not(ind));
y = y(not(ind));

plot([0 0],[-50 300],'k--');
plot([-50 300],[0 0],'k--');
[b,bci] = regress(y,[ones(size(x)),x]);
plot([-50 300],b(1) + b(2)*[-50 300],'r-');

text(150,20,sprintf('y=%1.2f + %1.2fx, r=%1.2f',b(1),b(2),corr(x,y)),'fontsize',14);
for i = 1:size(pLavg,1)
   if not(isnan(pLavg(i)))
      plot(pLbrown(i),pupdrs(i),'k.');
      text(pLbrown(i),pupdrs(i),info(i).PATIENTID,'rotation',45);
   end
end
for i = 1:size(pLavg,1)
   if not(isnan(pLavg(i)))
      plot(pRbrown(i),pupdrs(i),'k.');
      text(pRbrown(i),pupdrs(i),info(i).PATIENTID,'rotation',45);
   end
end
axis([-50 300 0 105]);

[pLavg,pRavg,pLbrown,pRbrown] = getPower(m,'msup');
figure(2); hold on
xlabel('Beta band power change (% re off)')
ylabel('UPDRS change total (%)')
title('Band average method');
x = [pLavg;pRavg];
y = [pupdrs;pupdrs];
ind = isnan(x(:,1))|isnan(y);
x = x(not(ind),:);
y = y(not(ind));

plot([0 0],[-50 300],'k--');
plot([-50 300],[0 0],'k--');
[b,bci] = regress(y,[ones(size(x,1),1),x]);
plot([-50 300],b(1) + b(2)*[-50 300],'r-');

text(50,20,sprintf('y=%1.2f + %1.2fx, r=%1.2f',b(1),b(2),corr(x(:,1),y(:,1))),'fontsize',14);
for i = 1:size(pLavg,1)
   if not(isnan(pLavg(i)))
      plot(pLavg(i,:),repmat(pupdrs(i),1,3),'kx');
      for j = 1%:3
         text(pLavg(i,j),pupdrs(i),m(i).patient(1:min(4,numel(m(i).patient))),'rotation',45);
      end
   end
end
for i = 1:size(pLavg,1)
   if not(isnan(pLavg(i)))
      plot(pRavg(i,:),repmat(pupdrs(i),1,3),'kx');
%       for j = 1%:3
%          text(pRavg(i,j),pupdrs(i),m(i).patient(1:min(4,numel(m(i).patient))),'rotation',45);
%       end
   end
end

axis([-50 100 0 105]);