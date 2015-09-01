function h = plot(self,varargin)

p = inputParser;
p.KeepUnmatched= true;
p.FunctionName = 'EventProcess plot method';
p.addParamValue('handle',[],@(x) isnumeric(x) || ishandle(x));
p.parse(varargin{:});
params = p.Unmatched;

if isempty(p.Results.handle) || ~ishandle(p.Results.handle)
   figure;
   h = subplot(1,1,1);
else
   h = p.Results.handle;
   axes(h);
end
hold on;
ylim = get(h,'ylim');

values = self.values{1};
c = fig.distinguishable_colors(numel(values));
for i = 1:numel(values)
   left = values(i).time(1);
   right = values(i).time(2);
   bottom = ylim(1);
   top = ylim(2);
   eFill(i) = fill([left left right right],[bottom top top bottom],...
      c(i,:),'FaceAlpha',0.15,'EdgeColor','none');
   set(eFill(i),'Tag','Event');
   eText(i) = text(left,top,values(i).name,'VerticalAlignment','bottom',...
      'FontAngle','italic');
   set(eText(i),'Tag','Event');
end