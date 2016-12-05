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
      %color = [0 0 0]
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
         p.addParamValue('name','',@(x) ischar(x) || isa(x,'metadata.Label'));
         p.addParamValue('description','',@ischar);
         p.addParamValue('timeUnit','seconds',@ischar);
         p.addParamValue('timeReference',[],@(x) isa(x,'metadata.Event'));
         p.addParamValue('tStart',[],@isnumeric);
         p.addParamValue('tEnd',[],@isnumeric);
         p.addParamValue('experiment',[],@(x) isa(x,'metadata.Experiment'));
         p.addParamValue('color',[],@(x) isnumeric(x) || any(strcmp(x,{'b' 'g' 'r' 'c' 'm' 'y' 'k'})));
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

         if ~isempty(par.color)
            if isa(self.name,'metadata.Label')
               if ischar(par.color)
                  self.name.color = str2rgb(par.color);
               else
                  self.name.color = par.color;
               end
            else
               %warning('no color set');
            end
         end
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
      
      function [events,bool] = match(self,varargin)
         if (nargin==2) && isstruct(varargin{1})
            par = varargin{1};
         else
            p = inputParser;
            p.KeepUnmatched= false;
            p.FunctionName = 'metadata.Event match method';
            p.addParamValue('eventProp','name',@ischar);
            p.addParamValue('eventVal',[]);
            p.addParamValue('nansequal',true,@islogical);
            p.addParamValue('strictHandleEq',false,@islogical);p.parse(varargin{:});
            par = p.Results;
         end
         
         nObj = numel(self);
         
         if ~isempty(par.eventVal)
            if ischar(par.eventVal)
               v = arrayfun(@(x) strcmp(x.(par.eventProp),par.eventVal),self,'uni',0,'ErrorHandler',@valErrorHandler);
            else
               if par.nansequal && ~par.strictHandleEq
                  % equality of numerics as well as values in fields of structs & object properties
                  % NaNs are considered equal
                  v = arrayfun(@(x) isequaln(x.(par.eventProp),par.eventVal),self,'uni',0,'ErrorHandler',@valErrorHandler);
               elseif ~par.nansequal && ~par.strictHandleEq
                  % equality of numerics as well as values in fields of structs & object properties
                  % NaNs are not considered equal
                  v = arrayfun(@(x) isequal(x.(par.eventProp),par.eventVal),self,'uni',0,'ErrorHandler',@valErrorHandler);
               else
                  % This will match handle references, ie. false even if contents match
                  v = arrayfun(@(x) x.(par.eventProp)==par.eventVal,self,'uni',0,'ErrorHandler',@valErrorHandler);
               end
            end
            bool = vertcat(v{:});
         else
            bool = false(nObj,1);
         end
         events = self(bool);         
      end
   end
end

function result = valErrorHandler(err,varargin)
   if strcmp(err.identifier,'MATLAB:noSuchMethodOrField');
      result = false;
   else
      err = MException(err.identifier,err.message);
      cause = MException('EventProcess:find:eventProp',...
         'Problem in eventProp/Val pair.');
      err = addCause(err,cause);
      throw(err);
   end
end