% TODO
% o common timescale
% o gui elements allowing scrolling
function [h,yOffset] = plot(self,varargin)

p = inputParser;
p.KeepUnmatched= true;
p.FunctionName = 'SampledProcess plot method';
p.addParamValue('handle',[],@(x) isnumeric(x) || ishandle(x));
p.addParamValue('stack',0,@(x) isnumeric(x) || islogical(x));
p.addParamValue('sep',3,@(x) isscalar(x));
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

values = self.values{1};
t = self.times{1};
if p.Results.stack
   n = size(values,2);
   sf = (0:n-1)*p.Results.sep;
   plot(t,bsxfun(@plus,values,sf));
   plot(repmat([t(1) t(end)]',1,n),[sf' , sf']','--','color',[.7 .7 .7 .4]);
else
   plot(t,values);
end
