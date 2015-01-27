% Class for collecting Sampled, Point and EventProcesses with common start
% and end time.
% o Probably should place tStart/tEnd
% o must check for common start and end times!

% o methods for 
%   o adding processes
%   o 
% 
classdef(CaseInsensitiveProperties, TruncatedProperties) Segment < hgsetget & matlab.mixin.Copyable
   properties
      info@containers.Map % Information about segment
   end
   properties
      labels
      processes
   end
   properties(SetAccess = private, Dependent = true)
      type
      
      tStart
      tEnd
      window
      offset
      
      sameWindow
      sameOffset
   end
   
   methods
      %% Constructor
      function self = Segment(varargin)
         % TODO
         % if all inputs are of type PointProcess or SampledProcess,
         % cat and add (no need to pass in paramvalue)
         
         p = inputParser;
         p.KeepUnmatched= false;
         p.FunctionName = 'Segment constructor';
         p.addParamValue('info',containers.Map('KeyType','char','ValueType','any'));
         p.addParamValue('process',[],@(x) iscell(x) || all(isa(x,'Process')) );
         p.addParamValue('labels',{},@(x) iscell(x) || ischar(x));
%          p.addParamValue('window',[],@isnumeric);
%          p.addParamValue('offset',0,@isnumeric);
%          p.addParamValue('tStart',[],@isnumeric);
%          p.addParamValue('tEnd',[],@isnumeric);
         p.parse(varargin{:});
         par = p.Results;

         self.info = par.info;
         
         self.processes = {};
         if ~isempty(par.process)
            if iscell(par.process)
               self.processes = cat(2,self.processes,par.process);
            else
               self.processes = cat(2,self.processes,{par.process});
            end
         end
keyboard
%          self.processes = {};
%          validProcess = {'PointProcess' 'SampledProcess' 'EventProcess'};
%          for i = 1:numel(validProcess)
%             if ~isempty(par.(validProcess{i}))
%                if iscell(par.(validProcess{i}))
%                   self.processes = cat(2,self.processes,par.(validProcess{i}));
%                else
%                   self.processes = cat(2,self.processes,{par.(validProcess{i})});
%                end
%             end
%          end
%          
%          if ~isempty(par.PointProcess)
%             if iscell(par.PointProcess)
%                self.processes = cat(2,self.processes,par.PointProcess);
%             else
%                self.processes = cat(2,self.processes,{par.PointProcess});
%             end
%          end
%          if ~isempty(par.SampledProcess)
%             if iscell(p.Results.SampledProcess)
%                self.processes = cat(2,self.processes,par.SampledProcess);
%             else
%                self.processes = cat(2,self.processes,{par.SampledProcess});
%             end
%          end
%          if ~isempty(par.EventProcess)
%             if iscell(par.EventProcess)
%                self.processes = cat(2,self.processes,par.EventProcess);
%             else
%                self.processes = cat(2,self.processes,{par.EventProcess});
%             end
%          end
         
         % Create labels
         self.labels = p.Results.labels;
      end
      
      function list = get.type(self)
         list = cellfun(@(x) class(x),self.processes,'uni',0);
      end
      
      function bool = get.sameWindow(self)
         % FIXME: this assumes each segment has single window
         window = cellfun(@(x) x.window,self.processes,'uni',0);
         window = unique(vertcat(window{:}),'rows');
         if size(window,1) == 1
            bool = true;
         else
            bool = false;
         end
      end
      
      function bool = get.sameOffset(self)
         % FIXME: this assumes each segment has single offset
         offset = cellfun(@(x) x.offset,self.processes,'uni',0);
         offset = unique(vertcat(offset{:}),'rows');
         if size(offset,1) == 1
            bool = true;
         else
            bool = false;
         end
      end
      
      function set.labels(self,labels)
         % FIXME, prevent clashes with attribute names
         % FIXME, should check that labels are unique
         n = numel(self.processes);
         if isempty(labels)
            for i = 1:n
               labels{1,i} = ['pid' num2str(i)];
            end
            self.labels = labels;
         elseif iscell(labels)
            if numel(labels) == n
               if all(cellfun(@isstr,labels))
                  self.labels = labels;
               else
                  error('bad label');
               end
            else
               error('mismatch');
            end
         elseif (n==1) && ischar(labels)
            self.labels = {labels};
         else
            error('bad label');
         end
      end
      
      self = sync(self,event,varargin)
      
      proc = extract(self,request,flag)
      % reset
      % window
      % offset
   end
   
end
