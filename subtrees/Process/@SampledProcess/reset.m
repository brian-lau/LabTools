% Reset windows & offsets to state when object was created if it
% has not been chopped, otherwise to when it was chopped.
%
% SEE ALSO
% setInclusiveWindow

function self = reset(self)

for i = 1:numel(self)
   self(i).chain = {};

   if self(i).lazyLoad
      self(i).times = self(i).times_;
      self(i).values = {};
      self(i).isLoaded = false;
      self(i).window = self(i).window_;
      self(i).cumulOffset = 0;
      self(i).offset = self(i).offset_;
   else
      self(i).times = self(i).times_;
      self(i).values = self(i).values_;
      
      self(i).reset_ = true;
      self(i).window = self(i).window_;
      self(i).reset_ = false;
      
      % Directly apply window in case window_ = window
      % FIXME should actually check if window is different before applying
      applyWindow(self(i));
      
      self(i).cumulOffset = 0;
      self(i).offset = self(i).offset_;
   end
   
   self(i).Fs = self(i).Fs_;
end
