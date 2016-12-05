function obj = loadobj(S)
%keyboard
if isinteger(S)
   S = getArrayFromByteStream(S);
end

if checkVersion(S.version,'0.2.0')
   obj = Segment(...
      'info',S.info,...
      'process',S.processes,...
      'labels',S.labels...
      );
   %obj.window = S.window;
   %obj.offset = S.offset;
else
   disp('segment loadobj too old');
end