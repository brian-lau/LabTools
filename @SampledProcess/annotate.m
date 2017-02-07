% Generate EventProcess matching SampledProcess
% Right-clicking allows adding events to annotate the corresponding
% SampledProcess

function ep = annotate(self,h,ep)

if nargin == 2
   % Create array of EventProcesses that correspond to above, using a null
   % event as a placeholder
   null = metadata.Event('name','NULL','tStart',NaN,'tEnd',NaN);
   for i = 1:numel(self)
      ep(i) = EventProcess('events',null,'tStart',self(i).tStart,'tEnd',self(i).tEnd);
   end
else
   assert(numel(self)==numel(ep),'arrays do not match');
   assert(all([self.tStart]==[self.tStart]),'arrays do not match');
   assert(all([self.tEnd]==[self.tEnd]),'arrays do not match');
end

% De
l = findobj(h,'Type','Line');
if isempty(l)
   plot(self,'handle',h);
elseif all(ismember(self.labels,[l.UserData]))
   % do nothing
else
   % TODO: handle when only some are plotted
   plot(self,'handle',h);
end
plot(ep,'handle',h,'patchcallback',{@testPatchClick ep});

%h = plot(self);
% Add events to the plot
%plot(ep,'handle',h);
% If you prefer non-overlapping, try below instead
%plot(ep,'handle',h,'overlap',-.05,'stagger',true);

function testPatchClick(src,event,obj)
thisfig = ancestor(src,'Figure');
if strcmp(thisfig.SelectionType,'extend')
   h = datacursormode(thisfig);
   h.UpdateFcn = {@labelNames obj};
   h.SnapToDataVertex = 'off';
   h.Enable = 'on';
   
   set(thisfig,'WindowButtonMotionFcn',{@testit event h});
end

function txt = labelNames(~,event,obj)
ev = obj.find('eventVal',event.Target.UserData);
if isprop(ev,'labels')
   txt = {ev.labels.name}';
else
   txt = 'no associated labels';
end

function testit(x,y,event,h)
h.Enable = 'off';
h.removeAllDataCursors;