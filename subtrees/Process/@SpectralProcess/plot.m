% TODO
% o common timescale
% o gui elements allowing scrolling
function varargout = plot(self,varargin)

p = inputParser;
p.KeepUnmatched= true;
p.FunctionName = 'SpectralProcess plot method';
p.addParameter('handle',[],@(x) isnumeric(x) || ishandle(x));
p.addParameter('colorbar',0,@(x) isnumeric(x) || islogical(x));
p.addParameter('colormap',0,@(x) isnumeric(x) || islogical(x));
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
      g = subplot(numel(self),1,i); hold on
      plot(self(i),'handle',g,varargin{:});
   end
   return
end

% FIXME multiple windows?
values = self.values{1};
t = self.times{1};
f = self.f;

n = numel(self.labels);
if numel(t) == 1
   for i = 1:n
      subplot(n,1,i); hold on;
      plot(f,10*log10(abs(values(:,:,i)')));
      axis tight;
   end
else
   for i = 1:n
      subplot(n,1,i); hold on;
      imagesc('Xdata',t,'Ydata',f,'CData',10*log10(abs(values(:,:,i)')));
      axis tight;
      colorbar;
   end
end

if nargout >= 1
   varargout{1} = h;
end