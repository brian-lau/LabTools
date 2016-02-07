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
   for i = 1:numel(self)
      g = subplot(numel(self),1,i); hold on
      plot(self(i),'handle',g,varargin{:});
   end
   return
end

% FIXME multiple windows?
values = self.values{1};
t = self.times{1};
if p.Results.stack
   n = size(values,2);
   sf = (0:n-1)*p.Results.sep;
   plot(t,bsxfun(@plus,values,sf),'Parent',h);
   plot(repmat([t(1) t(end)]',1,n),[sf' , sf']','--','color',[.7 .7 .7 .4],'Parent',h);
else
   plot(t,values,'Parent',h);
end

if nargout
   hh = h;
end