% Event
classdef Event < metadata.Section
   properties
      name
      description
      timeUnit
      timeReference
      time
      duration
      experiment
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
         p.addParamValue('time','',@(x) ischar(x)||isscalar(x));
         p.addParamValue('duration',0,@isscalar);
         p.addParamValue('experiment',[],@(x) isa(x,'metadata.Experiment'));
         p.parse(varargin{:});
         par = p.Results;
         
         self.name = par.name;
         self.description = par.description;
         self.timeUnit = par.timeUnit;
         self.timeReference = par.timeReference;
         self.time = par.time;
         self.duration = par.duration;
         self.experiment = par.experiment;
      end
   end
end