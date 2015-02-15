function [peakLoc,peakMag,peakDetected,truepeak,bandmax,bandavg] = psdpeak(p,f,frange)
%function [peakLoc,peakMag,peakDetected,truepeak,bandmax] = psdpeak(p,f,frange,sel,thresh,inc_endpoints)

% if nargin < 6
%    inc_endpoints = true;
% end
% 
% if nargin < 5
%     thresh = [];
% end
% 
% if nargin < 4
%     sel = [];
% end

ind = (f>=frange(1)) & (f<=frange(2));
p_orig = p;
f_orig = f;
p = p(ind,:);
f = f(ind);

peakDetected = zeros(1,size(p,2));
for i = 1:size(p,2)
   %[tempLoc, tempMag] = peakfinder(p(:,i),sel,thresh,[],inc_endpoints);
   
   [tempMag,tempLoc] = findpeaks(p(:,i),'minpeakdistance',5,'threshold',0);
   if ~isempty(tempLoc)
      tempLoc = unique(tempLoc);
      tempMag = p(tempLoc,i); % FIXME, hack because peakfinder returns strange!!!
      ind2 = find(tempMag==max(tempMag));
      peakMag(i) = tempMag(ind2);
      peakLoc(i) = f(tempLoc(ind2));
      peakDetected(i) = true;
      if (f(tempLoc(ind2)) == f(1)) || (f(tempLoc(ind2)) == f(end))
         truepeak(i) = false;
      else
         truepeak(i) = true;
      end
   else
      truepeak(i) = false;
      peakDetected(i) = false;
      peakMag(i) = max(p(:,i));
      if isnan(peakMag(i))
         peakLoc(i) = NaN;
      else
         peakLoc(i) = f(p(:,i) == peakMag(i));
      end
   end
end

bandmax = max(p);
bandmax = bandmax == max(bandmax);

bandavg = mean(p);

if nargout == 0
   maxPeakMag = max(peakMag);max
   maxPeakLoc = peakLoc(peakMag == maxPeakMag);
   figure;
   for i = 1:size(p,2)
      subplot(size(p,2),1,i); hold on
      plot(f_orig,p_orig(:,i)); axis tight
      plot(peakLoc(i),peakMag(i),'rs'); %carr? rouge
      if peakDetected
         plot(peakLoc(i),peakMag(i),'cs'); %carr? cyan
      else
          plot(peakLoc(i),peakMag(i),'go'); %cercle vert
      end
      if peakMag(i) == maxPeakMag
         plot(maxPeakLoc,maxPeakMag,'ms','markersize',12);
      end
      plot([frange(1) frange(1)],get(gca,'ylim'),'r');
      plot([frange(2) frange(2)],get(gca,'ylim'),'r');
   end
end



