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
p.KeepUnmatched= true;
p.FunctionName = 'SpectralProcess plot method';
p.addParameter('handle',[],@(x) isnumeric(x) || ishandle(x));
p.addParameter('colorbar',true,@(x) isnumeric(x) || islogical(x));
p.addParameter('colormap','parula',@(x) ischar(x) || isnumeric(x));
p.addParameter('caxis',[],@isnumeric);
p.addParameter('shading','interp',@ischar);
p.addParameter('log',true,@(x) islogical(x) || isscalar(x));
p.parse(varargin{:});
%params = p.Unmatched;

par = p.Results;

if isempty(p.Results.handle) || ~ishandle(p.Results.handle)
   h = figure;
else
   h = p.Results.handle;
end

% if numel(self) > 1
%    for i = 1:numel(self)
%       g = subplot(numel(self),1,i); hold on
%       plot(self(i),'handle',g,varargin{:});
%    end
%    return
% end

% FIXME multiple windows?
values = self.values{1};
t = self.times{1} + self.tBlock/2;
f = self.f;

n = numel(self.labels);
for i = 1:n
   g = subplot(n,1,i,'Parent',h);
   cla(g);
   if par.log
      v = 10*log10(abs(values(:,:,i)'));
   else
      v = abs(values(:,:,i)');
   end
   
   if numel(t) == 1
      plot(f,v);
   else
      args = {t,f,v};
      surf(args{:},'edgecolor','none','Parent',g);
      view(g,0,90);
%       % imagesc cannot plot irregularly spaced data (eg, wavelet)
%       % maybe try imagescnan FEX
%       imagesc('Xdata',t,'Ydata',f,'CData',v,'Parent',g);

      if ~isempty(par.caxis)
         caxis(par.caxis);
      end

      shading(g,par.shading);      
      colormap(par.colormap);
      if par.colorbar
         colorbar;
      end
   end
%   title(self.labels{i});
   axis tight;
end

if nargout
   hh = h;
end