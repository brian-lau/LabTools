classdef(CaseInsensitiveProperties, TruncatedProperties) EventProcess < PointProcess         
   properties(SetAccess = private, Dependent = true, Transient = true)
      duration  % # of events in window
      isValidEvent
   end
   
   methods
      %% Constructor
      function self = EventProcess(varargin)
         self = self@PointProcess(varargin{:});
         
         % check that each event has start and end time
      end
      
      function duration = get.duration(self)
         % duration of events within windows
         if isempty(self.times)
            duration = NaN;
         else
            duration = cellfun(@(x) x(:,2)-x(:,1),self.times,'uni',0);
         end
      end
      
      function bool = get.isValidEvent(self)
         % start/end time of events fall within windows?
         if isempty(self.times)
            bool = false;
         else
            bool = cellfun(@(times,win) (times(:,1)>=win(:,1))&(times(:,2)<=win(:,2)),...
               self.times,{self.window},'uni',0);
         end
      end
   end
end

