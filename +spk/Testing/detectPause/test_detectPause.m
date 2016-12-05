import spk.*

t = 0:.001:15;
r = ones(size(t))*60;

ind = (t>1)&(t<1.5);
r(ind) = 1;
ind = (t>3)&(t<3.5);
r(ind) = 3;
ind = (t>5)&(t<5.5);
r(ind) = 9;
ind = (t>7)&(t<7.5);
r(ind) = 18;
ind = (t>9)&(t<9.5);
r(ind) = 36;

reps = 20;
spkcell = cell(reps,1);
for i = 1:reps
   [ISIs,SpkTime] = InHomoPoisSpkGen(r, t, 100);
   spkcell{i,1} = SpkTime;
end

%pauses = detectPause(spk,baseline,coreISI,maxAddedISI,minISI,maxMergeSpk);
pauses = detectPause(spkcell,60,.05,5,.3,3);

p = cell(reps,1);
for i = 1:reps
   if ~isempty(pauses(i).times);
      p{i,1} = mean(pauses(i).times,2);
   else
      p{i,1} = [];
   end
end

[ps,t] = getPsth(p,20,'window',[0 15],'method','qkde');

n = 10;
plotPause(spkcell(1:n),pauses(1:n),1,1,1);
hold on;
plot(t,(r/60)+n+1,'r');
