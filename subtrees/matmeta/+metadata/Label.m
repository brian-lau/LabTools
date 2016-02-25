classdef Label < handle & matlab.mixin.Heterogeneous & matlab.mixin.Copyable
   properties
      name
      description
      comment
      grouping
   end
   
   methods
      function self = Label(varargin)
         if nargin == 0
            return;
         end
         
         p = inputParser;
         p.KeepUnmatched= true;
         p.addParameter('name','');
         p.addParameter('description','');
         p.addParameter('comment','');
         p.addParameter('grouping','');
         p.parse(varargin{:});
         par = p.Results;
         
         self.name = par.name;
         self.description = par.description;
         self.comment = par.comment;
         self.grouping = par.grouping;
      end
   end
   
   methods(Sealed = true)
      function [labels,bool] = match(self,varargin)
         if (nargin==2) && isstruct(varargin{1})
            par = varargin{1};
         else
            p = inputParser;
            p.KeepUnmatched= false;
            p.FunctionName = 'metadata.Label match method';
            p.addParameter('label',[],@(x) ischar(x) || iscell(x) || isa(x,'metadata.Label'));
            p.addParameter('labelProp','name',@ischar);
            p.addParameter('labelVal',[]);
            p.addParameter('nansequal',true,@islogical);
            p.addParameter('strictHandleEq',false,@islogical);p.parse(varargin{:});
            par = p.Results;
         end
         
         nObj = numel(self);
         
         if ~isempty(par.label) % requires full label match (ignores labelProp/Val)
            if isa(par.label,'metadata.Label')
               [~,ind] = intersect(self,par.label,'stable');
               bool = false(nObj,1);
               bool(ind) = true;
            end
         elseif ~isempty(par.labelVal)
            if ischar(par.labelVal)
               v = arrayfun(@(x) strcmp(x.(par.labelProp),par.labelVal),self,'uni',0,'ErrorHandler',@valErrorHandler);
            else
               if par.nansequal && ~par.strictHandleEq
                  % equality of numerics as well as values in fields of structs & object properties
                  % NaNs are considered equal
                  v = arrayfun(@(x) isequaln(x.(par.labelProp),par.labelVal),self,'uni',0,'ErrorHandler',@valErrorHandler);
               elseif ~par.nansequal && ~par.strictHandleEq
                  % equality of numerics as well as values in fields of structs & object properties
                  % NaNs are not considered equal
                  v = arrayfun(@(x) isequal(x.(par.labelProp),par.labelVal),self,'uni',0,'ErrorHandler',@valErrorHandler);
               else
                  % This will match handle references, ie. false even if contents match
                  v = arrayfun(@(x) x.(par.labelProp)==par.labelVal,self,'uni',0,'ErrorHandler',@valErrorHandler);
               end
            end
            bool = vertcat(v{:});
         else
            bool = false(nObj,1);
         end
         labels = self(bool);
      end
      
   end
end

function result = valErrorHandler(err,varargin)
   if strcmp(err.identifier,'MATLAB:noSuchMethodOrField');
      result = false;
   else
      err = MException(err.identifier,err.message);
      cause = MException('Process:subset:eventProp',...
         'Problem in eventProp/Val pair.');
      err = addCause(err,cause);
      throw(err);
   end
end