% TODO
% o common timescale
% o gui elements allowing scrolling
function varargout = plot(self,varargin)

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
   axes(h);
end
hold on;

if numel(self) > 1
   for i = 1:numel(self)
      subplot(numel(self),1,i); hold on
      y = self(i).values{1};
      plot(self(i).times{1},y);
   end
   return
end

% FIXME multiple windows?
values = self.values{1};
values = reshape(values,self.dim{1}(1),prod(self.dim{1}(2:end)));
t = self.times{1};
if p.Results.stack
   n = size(values,2);
   sf = (0:n-1)*p.Results.sep;
   plot(t,bsxfun(@plus,values,sf));
   plot(repmat([t(1) t(end)]',1,n),[sf' , sf']','--','color',[.7 .7 .7 .4]);
else
   plot(t,values);
end

if nargout >= 1
   varargout{1} = h;
end