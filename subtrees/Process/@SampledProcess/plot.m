% TODO
% o common timescale
% o gui elements allowing scrolling
function hh = plot(self,varargin)

   p = inputParser;
   p.KeepUnmatched= true;
   p.FunctionName = 'SampledProcess plot method';
   p.addParameter('handle',[],@(x) isnumeric(x) || ishandle(x));
   p.addParameter('stack',0,@(x) isnumeric(x) || islogical(x));
   p.addParameter('sep',3,@(x) isscalar(x));
   p.parse(varargin{:});
   %params = p.Unmatched;

   if isempty(p.Results.handle) || ~ishandle(p.Results.handle)
      figure;
      h = subplot(1,1,1);
   else
      h = p.Results.handle;
   end
   hold(h,'on');
   
   if numel(self) > 1
      self = self(1);
   end

   % FIXME multiple windows?
   values = self.values{1};
   t = self.times{1};
   plotLines(t,values,p.Results.stack,p.Results.sep,self.labels,self,h);
   setLabels(h);
   
   if nargout
      hh = h;
   end

end

function plotLines(t,values,stack,sep,labels,obj,h)
   if stack
      n = size(values,2);
      sf = (0:n-1)*sep;
      lh = plot(t,bsxfun(@plus,values,sf),'Parent',h);
      plot(repmat([t(1) t(end)]',1,n),[sf' , sf']','--','color',[.7 .7 .7 .4],'Parent',h);
   else
      lh = plot(t,values,'Parent',h);
   end
   % Distribute label colors, masking for quality=0
   q0 = obj.quality == 0;
   [lh(~q0).Color] = deal(obj.labels(~q0).color);
   [lh(q0).Color] = deal([.7 .7 .7 .4]);

   % Attach menus
   lineMenu = uicontextmenu();
   m1 = uimenu(lineMenu,'Label','Quick set quality = 0','Callback',{@setQuality obj 0});
   m2 = uimenu(lineMenu,'Label','Change color','Callback',{@pickColor obj h});
   m3 = uimenu(lineMenu,'Label','Edit label','Callback',{@testme obj h});
   m3 = uimenu(lineMenu,'Label','Edit quality','Callback',{@testme obj h});
   set(lh,'uicontextmenu',lineMenu);
   for i= 1:numel(lh)
      set(lh(i),'UserData',labels(i),'Tag','Label');
   end
end

function setLabels(h,label)
   right = h.XLim(2);
   lh = findall(h,'Tag','Label');
   if nargin < 3
      for i = 1:numel(lh)
         text(right,lh(i).YData(end),lh(i).UserData.name,'VerticalAlignment','middle',...
            'FontAngle','italic','Color',lh(i).UserData.color,...
            'UserData',lh(i).UserData,'Tag','TextLabel','Parent',h);
      end
   else
      th = findall(h,'Tag','TextLabel');
      ind = find([th.UserData]==label);
      for i = ind
         th(i).String = th(i).UserData.name;
         th(i).Color = th(i).UserData.color;
      end
   end
end

function setQuality(~,~,obj,quality)
   lh = gco;
   label = lh.UserData;
   ind = obj.labels == label;
   if any(ind)
      obj.quality(ind) = quality;
      if quality == 0
         lh.Color = [.7 .7 .7 .4];
      end
   end
end

function pickColor(~,~,obj,h)
   lh = gco;
   label = lh.UserData;
   ind = obj.labels == label;
   
   color = obj.labels(ind).color;
   
   if isa(h.UserData,'javax.swing.JColorChooser')
      cc = h.UserData;
   else
      cc = javax.swing.JColorChooser;
      cp = cc.getChooserPanels;
      cc.setChooserPanels(cp([4 1]));
   end
   cc.setColor(fix(color(1)*255),fix(color(2)*255),fix(color(3)*255));

   mouse = get(0,'PointerLocation');
   d = dialog('Position',[mouse 610 425],'Name','Select color');
   javacomponent(cc,[1,1,610,425],d);
   uiwait(d);
   color = cc.getColor;
   obj.labels(ind).color(1) = color.getRed/255;
   obj.labels(ind).color(2) = color.getGreen/255;
   obj.labels(ind).color(3) = color.getBlue/255;
   lh.Color = obj.labels(ind).color;
   h.UserData = cc;
   setLabels(h,label);
end
