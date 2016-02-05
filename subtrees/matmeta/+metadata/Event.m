% Event
% TODO:
%   o clean up setting of tStart/tEnd, ie, can Event have one but not other
classdef Event < metadata.Section & matlab.mixin.Heterogeneous
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
   properties(SetAccess = protected, Hidden = true)
      tStart_
      tEnd_
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
         p.addParameter('name','',@ischar);
         p.addParameter('description','',@ischar);
         p.addParameter('timeUnit','seconds',@ischar);
         p.addParameter('timeReference',[],@(x) isa(x,'metadata.Event'));
         p.addParameter('tStart',[],@isnumeric);
         p.addParameter('tEnd',[],@isnumeric);
         p.addParameter('experiment',[],@(x) isa(x,'metadata.Experiment'));
         p.parse(varargin{:});
         par = p.Results;
         
         self.name = par.name;
         self.description = par.description;
         self.timeUnit = par.timeUnit;
         self.timeReference = par.timeReference;
         self.tStart = par.tStart;
         self.tEnd = par.tEnd;
         self.experiment = par.experiment;
         self.tStart_ = self.tStart;
         self.tEnd_ = self.tEnd;
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

%       function set.tStart(self,tStart)
%          if isscalar(tStart)
%             self.tStart = tStart;
%          else
%             %error('tstart');
%             self.tStart = NaN;
%          end
% %          if isnan(tStart)
% %             self.tStart = tStart;
% %          elseif ~isempty(tStart)
% %             assert(isscalar(tStart) && isnumeric(tStart),'Event:tStart:InputFormat',...
% %                'tStart must be a numeric scalar.');
% %             if ~isempty(self.tEnd)
% %                assert(tStart <= self.tEnd,'Event:tStart:InputValue',...
% %                   'tStart must be <= tEnd.');
% %             end
% %             self.tStart = tStart;
% %          end
%       end
%       
%       function set.tEnd(self,tEnd)
%          if isscalar(tEnd)
%             self.tEnd = tEnd;
%          else
%             self.tEnd = NaN;
%             %error('tend');
%          end
% %          if isempty(tEnd)
% %             if ~isempty(self.tStart)
% %                self.tEnd = self.tStart;
% %             end
% %          elseif isnan(tEnd)
% %             self.tEnd = tEnd;
% %          else
% %             assert(isscalar(tEnd) && isnumeric(tEnd),'Event:tEnd:InputFormat',...
% %                'tEnd must be a numeric scalar.');
% %             if ~isempty(self.tStart)
% %                assert(self.tStart <= tEnd,'Event:tEnd:InputValue',...
% %                   'tStart must be <= tEnd.');
% %             end
% %             self.tEnd = tEnd;
% %          end
%       end
    end
   
   methods(Sealed = true)
      function self = fix(self)
         for i = 1:numel(self)
            self(i).tStart_ = self(i).tStart;
            self(i).tEnd_ = self(i).tEnd;
         end
      end
      
      function self = reset(self)
         for i = 1:numel(self)
            if self(i).tStart > self(i).tEnd_
               self(i).tStart = self(i).tStart_;
               self(i).tEnd = self(i).tEnd_;
            else
               self(i).tEnd = self(i).tEnd_;
               self(i).tStart = self(i).tStart_;
            end
         end
      end
   end
end