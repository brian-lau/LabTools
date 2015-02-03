classdef(CaseInsensitiveProperties, TruncatedProperties) EventProcess < PointProcess         
   properties(SetAccess = private, Dependent = true, Transient = true)
      duration  % # of events in window
      isValidEvent
   end
   
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

      function events = find(self,varargin)
         p = inputParser;
         p.KeepUnmatched= false;
         p.FunctionName = 'EventProcess find';
         p.addParamValue('name',[],@ischar);
         p.addParamValue('type',[],@ischar);
         p.parse(varargin{:});
         p = p.Results;

         query = linq(self.values{1});
         
         if ~isempty(p.name) && (query.count>0)
            query.where(@(x) strcmp(x.name,p.name)).select(@(x) x);
         end
         if ~isempty(p.type) && (query.count>0)
            query.ofType(p.type).select(@(x) x);
         end
         
         if query.count > 0
            events = query.toArray();
         else
            events = [];
         end
      end
      
%       function plot(self)
%          figure(2);
%          plot(randn(10,1),randn(10,1),'ro');
%       endE

   end
end

