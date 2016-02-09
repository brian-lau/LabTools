function obj = loadobj(S)

if checkVersion(S.version,'0.2.0')
   obj = Segment(...
      'process',S.process,...
      'labels',S.labels...
      );
   obj.window = S.window;
   obj.offset = S.offset;
else
   
end