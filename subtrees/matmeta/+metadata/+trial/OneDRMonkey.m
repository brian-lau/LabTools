classdef OneDRMonkey < metadata.Trial
   properties
      CounterTotalTrials
      CounterTrialsInBlock
      ConditionIndex
      ConditionName
      BlockIndex
      TargetIndex
      RewardIndex
      TrialResultStr
      IsRepeatTrial
      IsAbortTrial
      RT
      TT
      FixDuration
      TargetDuration
      RewardDelay
      ElapsedResponseTime
%       TargetOnsetTime
%       ResponseOnsetTime
%       FixOnsetTime
%       FeedbackOnsetTime
%       ITIOnsetTime
%       TrialEndOnsetTime
   end
   properties(SetAccess=protected)
      version = '0.1.0'
   end
   methods
      function self = OneDRMonkey(varargin)
         self = self@metadata.Trial;
         if nargin == 0
            return;
         end
         
         p = inputParser;
         p.KeepUnmatched = false;
         p.FunctionName = 'OneDRMonkey constructor';
         p.addParameter('CounterTotalTrials',[],@(x) isscalar(x) && isnumeric(x));
         p.addParameter('CounterTrialsInBlock',[],@(x) isscalar(x) && isnumeric(x));
         p.addParameter('ConditionIndex',[],@(x) isscalar(x));
         p.addParameter('ConditionName',[],@(x) ischar(x));
         p.addParameter('BlockedMode',[],@(x) isscalar(x));
         p.addParameter('BlockIndex',[],@(x) isscalar(x));
         p.addParameter('TrialResultStr',[],@(x) ischar(x));
         p.addParameter('IsRepeatTrial',[],@(x) isscalar(x));
         p.addParameter('IsAbortTrial',[],@(x) isscalar(x));
         p.addParameter('RT',[],@(x) isscalar(x) && isnumeric(x));
         p.addParameter('TT',[],@(x) isscalar(x) && isnumeric(x));
         p.addParameter('FixDuration',[],@(x) isscalar(x) && isnumeric(x));
         p.parse(varargin{:});
         par = p.Results;
         
         fn = fieldnames(par);
         for i = 1:numel(fn)
            self.(fn{i}) = par.(fn{i});
         end
      end
   end
end