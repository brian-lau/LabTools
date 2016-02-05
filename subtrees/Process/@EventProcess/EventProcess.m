% Event processes

classdef(CaseInsensitiveProperties) EventProcess < PointProcess         
   properties(SetAccess = private, Dependent)
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
         if mod(nargin,2)==1 && ~isstruct(varargin{1})
            assert(isa(varargin{1},'metadata.Event'),...
               'EventProcess:Constructor:InputFormat',...
                  'Single inputs must be passed in as array of metadata.Events');
            varargin = [{'events'} varargin];
         end
         
         p = inputParser;
         p.KeepUnmatched= true;
         p.FunctionName = 'EventProcess constructor';
         p.addParameter('Fs',1000,@(x) isnumeric(x) && isscalar(x));
         p.addParameter('events',[],@(x) isa(x,'metadata.Event') );
         p.parse(varargin{:});
         args = p.Unmatched;
         args.Fs = p.Results.Fs;
         
         if ~isempty(p.Results.events)
            times = vertcat(p.Results.events.time);
            args.times = roundToSample(times,1/args.Fs);
            args.values = p.Results.events(:);
            [args.values.tStart] = deal(args.times(:,1));
            [args.values.tEnd] = deal(args.times(:,2));
            args.values = args.values.fix();
         else
            args = {};
         end
         
         self = self@PointProcess(args);         
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
   
   methods(Static)
      obj = loadobj(S)
   end
end

