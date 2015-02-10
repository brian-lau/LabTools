library(lme4)
library(lattice)

library("plyr")
library(lmerTest)
library(multcomp)
data <- read.csv("/Users/brian/Documents/MATLAB/test.txt")
data <- within(data, {
  CHANNEL <- factor(CHANNEL)
})

# 'all' data sets have all neurons, with firing rate at multiple time points in window,
# average over the window
#data = ddply(data, .(patient,neuron,target,side,depth,steplength,frequency), summarise, r=mean(r))

tapply(data$f30, data$CONDITION, mean)

#lme0 = lmer(f30 ~ 1 + TASK + CONDITION + SIDE + CHANNEL + UPDRS_OFF + UPDRS_ON + (1|PATIENTID),data=data,REML=FALSE)
#lme0 = lmer(f15 ~ 1 + TASK + CONDITION + SIDE + CHANNEL + UPDRS_OFF + UPDRS_ON + (1|PATIENTID/SIDE/CHANNEL),data=data,REML=FALSE)
lme0 = lmer(f8 ~ 1 + TASK + CONDITION*CHANNEL + SIDE + UPDRS_OFF + UPDRS_ON + (1|PATIENTID/SIDE/CHANNEL),data=data,REML=FALSE)

fname = paste0("f",4:40)
base = "~ 1 + TASK + CONDITION*CHANNEL + SIDE + UPDRS_OFF + UPDRS_ON + (1|PATIENTID/SIDE/CHANNEL)"
for (i in 1:length(fname)) {
  fmla <- as.formula(paste(fname[i],base))
  lme = lmer(fmla,data=data,REML=FALSE)
  temp = anova(lme)
  if (i > 1){
    F = rbind(F,temp$F.value)
    P = rbind(P,temp$"Pr(>F)")
  } else {
    F = temp$F.value
    P = temp$"Pr(>F)"
  }
}
  
