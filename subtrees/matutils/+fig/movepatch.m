function movepatch(h,d,f)
%MOVEIT   Move a graphical object in 2-D.
%   Move an object in 2-D. Modify this function to add more functionality
%   when e.g. the object is dropped. It is not perfect but could perhaps
%   inspire some people to do better stuff.
%
%   d - optional, 'x', 'y' or 'xy' (default) to constrain movement
%   f - optional function handle, evaluated on movement termination
%
%   % Example:
%   t = 0:2*pi/20:2*pi;
%   X = 3 + sin(t); Y = 2 + cos(t); Z = X*0;
%   h = patch(X,Y,Z,'g')
%   axis([-10 10 -10 10]);
%   fig.movepatch(h);
%
%   % Example:
%   h = plot([0 0],[0 1]);
%   axis([-10 10 0 1]);
%   fig.movepatch(h,'x',@(x) disp('hello'));
%
% Author: Anders Brun, anders@cb.uu.se
%
% Copyright (c) 2009, Anders Brun
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
% 
%     * Redistributions of source code must retain the above copyright
%       notice, this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright
%       notice, this list of conditions and the following disclaimer in
%       the documentation and/or other materials provided with the distribution
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.

if nargin < 3
   f = [];
end
if nargin < 2
   d = 'xy';
end

oldButtonDownFcn = get(h,'ButtonDownFcn');
oldUserData = get(h,'UserData');
set(h,'ButtonDownFcn',{@startmovit d f});
thisfig = ancestor(h,'Figure');
gui.currenthandle = h;
gui.startpoint = [];
gui.XData = [];
gui.YData = [];

   function startmovit(src,~,d,f)
      % Remove mouse pointer
      set(thisfig,'PointerShapeCData',nan(16,16));
      set(thisfig,'Pointer','custom');

      % Set callbacks
      set(thisfig,'WindowButtonMotionFcn',{@movit d});
      set(thisfig,'WindowButtonUpFcn',{@stopmovit f});

      % Store starting point of the object
      gui.startpoint = get(ancestor(src,'Axes'),'CurrentPoint');
      gui.XData = get(gui.currenthandle,'XData');
      gui.YData = get(gui.currenthandle,'YData');
   end

   function movit(~,~,d)
      try
         if isequal(gui.startpoint,[])
            return
         end
      catch
      end

      % Do "smart" positioning of the object, relative to starting point...
      pos = get(ancestor(gui.currenthandle,'Axes'),'CurrentPoint')-gui.startpoint;
      if any(d=='x')
         set(gui.currenthandle,'XData',gui.XData + pos(1,1));
      end
      if any(d=='y')
         set(gui.currenthandle,'YData',gui.YData + pos(1,2));
      end
      %drawnow;
   end

   function stopmovit(~,~,f)
      % Clean up the evidence ...
      set(thisfig,'Pointer','arrow');
      set(thisfig,'WindowButtonUpFcn','');
      set(thisfig,'WindowButtonMotionFcn','');
      drawnow;
      set(gui.currenthandle,'UserData',oldUserData,'ButtonDownFcn',oldButtonDownFcn);
      if ~isempty(f)
         feval(f);
      end
   end
end
