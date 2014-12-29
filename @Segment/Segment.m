% collection of processes defined by common start and end time
% o Probably should place tStart/tEnd
% o must check for common start and end times!

% o methods for 
%   o adding processes
%   o 
classdef(CaseInsensitiveProperties, TruncatedProperties) Segment < hgsetget & matlab.mixin.Copyable
   properties
      info@containers.Map % Information about segment
   end
   properties
      labels
      data % FIXME: rename this to processes, validate through setter
   end
   properties(SetAccess = private, Dependent = true)
      dataType
      %window
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
         p.addParamValue('PointProcesses',[]);
         p.addParamValue('SampledProcesses',[]);
         p.addParamValue('labels',{},@(x) iscell(x) || ischar(x));
         p.parse(varargin{:});

         self.info = p.Results.info;
         self.data = {};
         if ~isempty(p.Results.PointProcesses)
            if iscell(p.Results.PointProcesses)
               self.data = cat(2,self.data,p.Results.PointProcesses);
            else
               self.data = cat(2,self.data,{p.Results.PointProcesses});
            end
         end
         if ~isempty(p.Results.SampledProcesses)
            if iscell(p.Results.SampledProcesses)
               self.data = cat(2,self.data,p.Results.SampledProcesses);
            else
               self.data = cat(2,self.data,{p.Results.SampledProcesses});
            end
         end
         
         % Create labels
         self.labels = p.Results.labels;
         
      end% constructor
      
      function list = get.dataType(self)
         list = cellfun(@(x) class(x),self.data,'uni',0);
      end
      
      function bool = get.sameWindow(self)
         % FIXME: this assumes each segment has single window
         window = cellfun(@(x) x.window,self.data,'uni',0);
         window = unique(vertcat(window{:}),'rows');
         if size(window,1) == 1
            bool = true;
         else
            bool = false;
         end
      end
      
      function bool = get.sameOffset(self)
         % FIXME: this assumes each segment has single offset
         offset = cellfun(@(x) x.offset,self.data,'uni',0);
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
         n = numel(self.data);
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
