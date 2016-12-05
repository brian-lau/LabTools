function plotPause(spk,pauses,plot0,plot1,plot2,labels)

import spk.*

if nargin < 5
   plot2 = false;
end
if nargin < 4
   plot1 = false;
end
if nargin < 3
   plot0 = false;
end

lw = 4;

figure;
h = subplot(1,1,1);hold on
plotRaster(spk,'handle',h);
for j = 1:length(spk)
   if plot0
      for i = 1:size(pauses(j).times0,1)
         if ~isempty(pauses(j).times0)
            plot(pauses(j).times0(i,:),j-[.3 .3],'b','linewidth',lw);
         end
      end
   end
   if plot1
      for i = 1:size(pauses(j).times1,1)
         if ~isempty(pauses(j).times1)
            plot(pauses(j).times1(i,:),j-[.1 .1],'g','linewidth',lw);
         end
      end
   end
   if plot2
      for i = 1:size(pauses(j).times2,1)
         if ~isempty(pauses(j).times2)
            plot(pauses(j).times2(i,:),j+[.1 .1],'c','linewidth',lw);
         end
      end
   end
   for i = 1:size(pauses(j).times,1)
      if ~isempty(pauses(j).times)
         plot(pauses(j).times(i,:),j+[.3 .3],'r','linewidth',lw);
      end
   end
end

if exist('labels','var')
   set(gca,'Ytick',1:length(labels),'Yticklabel',labels);
end