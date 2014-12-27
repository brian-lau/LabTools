function [P,F,win] = winpmtm(s,nw,f,winsize)

winstart = s.tStart:winsize:s.tEnd;
winend = [winstart(2:end) s.tEnd];
win = [winstart',winend'];
s.window = win;

P = zeros(numel(f),numel(s.labels),size(win,1));
for i = 1:numel(s.labels)
   for j = 1:size(win,1)
      x = s.values{j}(:,i);
      [P(:,i,j),F] = pmtm(x,nw,f,s.Fs);
   end
end
s.reset();
F = f;
