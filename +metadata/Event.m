% Event
% TODO:
%   o clean up setting of tStart/tEnd, ie, can Event have one but not other
classdef Event < metadata.Section
   properties
      name
      description
      timeUnit
      timeReference
      tStart
      tEnd
      experiment
   end
   properties(SetAccess = protected, Dependent = true, Transient = true)
      time
      duration
   end
   
   methods
      function self = Event(varargin)
         self = self@metadata.Section();
         if nargin == 0
            return;
         end
         
         p = inputParser;
         p.KeepUnmatched= true;
         p.FunctionName = 'Event constructor';
         p.addParamValue('name','',@ischar);
         p.addParamValue('description','',@ischar);
         p.addParamValue('timeUnit','seconds',@ischar);
         p.addParamValue('timeReference',[],@(x) isa(x,'metadata.Event'));
         p.addParamValue('tStart',[],@isnumeric);
         p.addParamValue('tEnd',[],@isnumeric);
         p.addParamValue('experiment',[],@(x) isa(x,'metadata.Experiment'));
         p.parse(varargin{:});
         par = p.Results;
         
         self.name = par.name;
         self.description = par.description;
         self.timeUnit = par.timeUnit;
         self.timeReference = par.timeReference;
         self.tStart = par.tStart;
         self.tEnd = par.tEnd;
         self.experiment = par.experiment;
      end
      
      function time = get.time(self)
         if ~isempty(self.tStart) && ~isempty(self.tEnd)
            time = [self.tStart self.tEnd];
         else
            time = [NaN NaN];
         end
      end
      
      function duration = get.duration(self)
         if ~isempty(self.tStart) && ~isempty(self.tEnd)
            duration = self.tEnd - self.tStart;
         else
            duration = NaN;
         end
      end
      
      function set.tStart(self,tStart)
         if ~isempty(tStart)
            assert(isscalar(tStart) && isnumeric(tStart),'Event:tStart:InputFormat',...
               'tStart must be a numeric scalar.');
            if ~isempty(self.tEnd)
               assert(tStart <= self.tEnd,'Event:tStart:InputValue',...
                  'tStart must be <= tEnd.');
            end
            self.tStart = tStart;
         end
      end
      
      function set.tEnd(self,tEnd)
         if isempty(tEnd)
            if ~isempty(self.tStart)
               self.tEnd = self.tStart;
            end
         else
            assert(isscalar(tEnd) && isnumeric(tEnd),'Event:tEnd:InputFormat',...
               'tEnd must be a numeric scalar.');
            if ~isempty(self.tStart)
               assert(self.tStart <= tEnd,'Event:tEnd:InputValue',...
                  'tStart must be <= tEnd.');
            end
            self.tEnd = tEnd;
         end
      end
   end
end