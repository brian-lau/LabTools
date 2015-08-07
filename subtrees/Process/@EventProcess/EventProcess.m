% Event processes

classdef(CaseInsensitiveProperties) EventProcess < PointProcess         
   properties(SetAccess = private, Dependent, Transient)
      duration           % duration of events in windows
      isValidEvent       % start/end time of events in windows?
   end
   properties
      nullEvent = metadata.Event('name','NULL','tStart',NaN,'tEnd',NaN)
   end
   
   %%
   methods
      %% Constructor
      function self = EventProcess(varargin)
         p = inputParser;
         p.KeepUnmatched= true;
         p.FunctionName = 'EventProcess constructor';
         p.addParamValue('events',[],@(x) isa(x,'metadata.Event') );
         p.parse(varargin{:});

         args = p.Unmatched;
         if ~isempty(p.Results.events)
            if all(isa(p.Results.events,'metadata.Event'))
               times = vertcat(p.Results.events.time);
               args.times = times;
               args.values = p.Results.events(:);               
            else
               times = vertcat(p.Results.events.time);
               times = [times , times+vertcat(p.Results.events.duration)];
               args.times = times;
               args.values = p.Results.events;
            end
         end
         self = self@PointProcess(args);
         
         % Should be able to handle case where metadata is directly passed
         % in
         
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
      
      ev = find(self,varargin)
      
      % add event
      % remove event
      
      %% Display
      h = plot(self,varargin)
   end
   
   methods(Access = protected)
      applyOffset(self,offset)
   end
end

