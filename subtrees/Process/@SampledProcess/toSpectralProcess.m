% handle object array
% handle windows?

function obj = toSpectralProcess(self)
keyboard

tBlock = 0.5;
tStep= 0.1;

nBlock = max(1,floor(tBlock/self.dt));
nStep = max(1,floor(tStep/self.dt));
tBlock = nBlock*self.dt;
tStep= nStep*self.dt;
f = 0:500;

window = nBlock;
noverlap = nBlock - nStep;
n = numel(self.labels);
for i = 1:n
   [temp,f,~] = spectrogram(self.values{1}(:,i)',window,noverlap,f,self.Fs);
   S(:,:,i) = abs(temp');
end

tfParams.tapers = [5 9];
tfParams.pad = 0;
tfParams.Fs = self.Fs;
tfParams.fpass = f;
[S,~,f] = mtspecgramc(self.values{1}, [tBlock tStep], tfParams);

obj = SpectralProcess(S,...
   'f',f,...
   'tBlock',tBlock,...
   'tStep',tStep,...
   'labels',self.labels,...
   'tStart',self.tStart,...
   'tEnd',self.tEnd,...
   'offset',self.offset,...
   'window',self.window...
   );

   % cumuloffset