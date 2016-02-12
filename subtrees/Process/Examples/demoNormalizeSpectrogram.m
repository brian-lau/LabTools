clear all
t = [0:0.001:2]';                    % 2 secs @ 1kHz sample rate
y1 = chirp(t,10,2,10,'q');
y2 = chirp(t,60,2,60,'q');
z1 = [y1;y1+y2];
z2 = [0.25*y1;y1+y2];

l(1) = metadata.Label('name','01D');
l(2) = metadata.Label('name','12D');
l(3) = metadata.Label('name','23D');
for i = 1:40
   if rem(i,2)
      s(i) = SampledProcess([z1+1*randn(size(z1)) , z2+randn(size(z2))],'Fs',1000,'labels',l(1:2));
   else
      s(i) = SampledProcess([z1+1*randn(size(z1)) , z2+randn(size(z2)) , 2*randn(size(z2))-1],'Fs',1000,'labels',l);
   end
end
s.setOffset(-2);

%plot(s(1:2),'stack',true);

tf = tfr(s,'method','stft','f',[0:1:100],'tBlock',.25,'tStep',.025);
%tf = tfr(s,'method','cwt','f',[1 100]);
%[tf_avg_no_norm , n] = mean(tf);
%plot(tf_avg_no_norm,'title',true);
 
tf.normalize(0,'window',[-1.75 0],'method','subtract');
tf_avg = mean(tf);
plot(tf_avg,'title',true,'log',false);
% 
tf.reset();
tf.normalize(0,'window',[-1.35 0],'method','z-score');
tf_avg = mean(tf);
%plot(tf_avg,'title',true,'log',false);
plot(tf_avg,'title',true,'log',false,'caxis',[-.2 1]);

tf.reset();
tf.normalize(0,'window',[-1.75 0],'method','divide');
tf_avg = mean(tf);
plot(tf_avg,'title',true,'log',false);

tf.reset();
tf.normalize(0,'window',[-1.75 0],'method','subtract-avg');
tf_avg = mean(tf);
plot(tf_avg,'title',true,'log',false);

tf.reset();
tf.normalize(0,'window',[-0.35 0],'method','z-score-avg');
tf_avg = mean(tf);
plot(tf_avg,'title',true,'log',false,'caxis',[-.2 1]);

tf.reset();
tf.normalize(0,'window',[-1.75 0],'method','divide-avg');
tf_avg = mean(tf);
plot(tf_avg,'title',true,'log',false);





tf = tfr(s,'method','stft','f',1:100,'tBlock',.5,'tStep',.02);
tf.normalize(0,'window',[-2 -2],'method','z-score-avg');


tf_avg = mean(tf,'labels',l);

tf.normalize(0,'window',[-1.75 -1.],'method','z-score-avg');
