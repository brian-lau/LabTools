function dat = convert2Fieldtrip(self)

win = self.window;
for i = 1:size(win,1)
   dat.trial{i} = self.values{i}';
   dat.time{i} = self.times{i}' - self.times{i}(1);
end
dat.sampleinfo = floor(self.window*self.Fs);
dat.sampleinfo = dat.sampleinfo + 1;
dat.label = self.labels;
