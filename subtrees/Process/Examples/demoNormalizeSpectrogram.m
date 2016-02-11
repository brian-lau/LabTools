clear all
t = [0:0.001:2]';                    % 2 secs @ 1kHz sample rate
y1 = chirp(t,10,2,10,'q');
y2 = chirp(t,60,2,60,'q');
z1 = [y1;y1+y2];
z2 = [0.25*y1;y1+y2];

l(1) = metadata.Label('name','01D');
l(2) = metadata.Label('name','12D');
l(3) = metadata.Label('name','23D');
for i = 1:50
   if rem(i,2)
      s(i) = SampledProcess([z1+randn(size(z1)) , z2+randn(size(z2))],'Fs',1000,'labels',l(1:2));
   else
      s(i) = SampledProcess([z1+randn(size(z1)) , z2+randn(size(z2)) , randn(size(z2))],'Fs',1000,'labels',l);
   end
end
s.setOffset(-2);

plot(s(1:2),'stack',true);

tf = tfr(s,'method','stft','f',1:100,'tBlock',.5,'tStep',.02);
[tf_avg_no_norm , n] = mean(tf);
plot(tf_avg_no_norm,'title',true);

tf.normalize(0,'window',[-1.75 -1.],'method','subtract');
tf_avg = mean(tf);
plot(tf_avg,'title',true);
