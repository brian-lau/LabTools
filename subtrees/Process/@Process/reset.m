% Reset windows & offsets to state when object was created if it
% has not been chopped, otherwise to when it was chopped.
%
% SEE ALSO
% setInclusiveWindow

function self = reset(self,n)

if nargin < 2
   n = 0;
else
   n = max(n,0);
end

for i = 1:numel(self)
   queue = self(i).queue;
   self(i).queue = {};

   % Evaluate eagerly without history
   self(i).running_ = true;

   if self(i).lazyLoad
      self(i).times = self(i).times_;
      self(i).values = {};
      self(i).isLoaded = false;
      self(i).reset_ = true;
      self(i).window = self(i).window_;
      self(i).reset_ = false;
      self(i).cumulOffset = 0;
      self(i).offset = self(i).offset_;
   else
      self(i).times = self(i).times_;
      self(i).values = self(i).values_;
      
      self(i).set_n();
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
   self(i).selection_ = true(1,self(i).n);
   self(i).labels = self(i).labels_;
   self(i).quality = self(i).quality_;
   
   % Turn deferred execution back on
   if self(i).deferredEval
      self(i).running_ = false;
   end
   
   if n
      queue = queue(1:n,:);
      for j = 1:size(queue,1)
         queue{j,3} = false;
      end
      self(i).queue = queue;
      
      if ~self(i).deferredEval
         evalOnDemand(self);
      end
   else
      clearQueue(self(i));
   end
end
