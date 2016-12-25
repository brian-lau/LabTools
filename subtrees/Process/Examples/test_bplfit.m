
ff = (1:.01:500)';
bl = stat.baseline.smbrokenpl([1 2 .5 2.5 20],ff);

tic;[beta,err] = stat.baseline.fit_smbrokenpl(ff,bl,'bp2'); toc
beta
err
blfit = stat.baseline.smbrokenpl(beta,ff);

figure; hold on
plot(ff,bl);
plot(ff,blfit);
set(gca,'xscale','log','yscale','log')

%%
ff = (1:.1:1500)';
bl = stat.baseline.smbrokenpl([1 2 .5 2 20 -2 4 500],ff);

tic;[beta,err] = stat.baseline.fit_smbrokenpl(ff,bl,'bp3'); toc
beta
err
blfit = stat.baseline.smbrokenpl(beta,ff);

figure; hold on
plot(ff,bl);
plot(ff,blfit);
set(gca,'xscale','log','yscale','log')