% TODO
% o common timescale
% o gui elements allowing scrolling
%function varargout = plot(self,varargin)
function hh = plot(self,varargin)

nObj = numel(self);
if nObj > 1
   for i = 1:nObj
      plot(self(i),varargin{:});
   end
   return
end

p = inputParser;
p.KeepUnmatched = true;
p.FunctionName = 'SpectralProcess plot method';
p.addParameter('handle',[],@(x) isnumeric(x) || ishandle(x));
p.addParameter('colorbar',true,@(x) isnumeric(x) || islogical(x));
p.addParameter('colormap','parula',@(x) ischar(x) || isnumeric(x));
p.addParameter('caxis',[],@isnumeric);
p.addParameter('shading','interp',@ischar);
p.addParameter('log',true,@(x) islogical(x) || isscalar(x));
p.addParameter('title',false,@(x) islogical(x) || isscalar(x));
p.parse(varargin{:});

par = p.Results;

if isempty(p.Results.handle) || ~ishandle(p.Results.handle)
   h = figure;
else
   h = p.Results.handle;
end

% FIXME multiple windows?
values = self.values{1};
if ~isreal(values)
   values = abs(values);
end
t = self.times{1} + self.tBlock/2;
f = self.f;

n = numel(self.labels);
for i = 1:n
   g = subplot(n,1,i,'Parent',h);
   cla(g);
   if par.log
      v = 10*log10(values(:,:,i)');
   else
      v = values(:,:,i)';
   end
   
   if numel(t) == 1
      plot(f,v,'color',self.labels(i).color);
   else
      surf(t,f,v,'edgecolor','none','Parent',g);
      view(g,0,90);
%       % imagesc cannot plot irregularly spaced data (eg, wavelet)
%       % maybe try imagescnan FEX
%       imagesc('Xdata',t,'Ydata',f,'CData',v,'Parent',g);

      if ~isempty(par.caxis)
         caxis(g,par.caxis);
      end

      shading(g,par.shading);      
      colormap(g,par.colormap);
      if par.colorbar
         colorbar;
      end
   end
   
   if par.title
      title(self.labels(i).name);
   end
   
   axis tight;
end

if nargout
   hh = h;
end