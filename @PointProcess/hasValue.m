% TODO handle PointProcess array
% return array in case of one window?
%          nWindow = size(self.window,1);
%          for i = 1:nWindow
%             bool(i,1) = valueFun(self,@(x) x==value);
%             times{i,1} = self.windowedTimes{i}(bool{i,1});
%          end

function [bool,times] = hasValue(self,value)

bool = valueFun(self,@(x) x==value);

nWindow = size(self.window,1);
for i = 1:nWindow
   times{i,1} = self.times{i}(bool{i,1});
end
