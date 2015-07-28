classdef Msup2 < metadata.Trial
   properties
      trial
      ruleBlockTrial
      colorBlockTrial
      currentRule
      currentColor
      rewardN_match
      reward_match
      rewardN_nonmatch
      reward_nonmatch
      posTar1
      posTar2
      posFix
      colTar1
      colTar2
      colFeed
      colFeedC
      delay
      overlap
      stopTrial
      targetShapeMatchCue
      shrinkIncorrect
      reacquireProb
      reacquireProbFree
      incorrectVisible
      displayCounterfactual
      sync
      isTar1Chosen
      isTar2Chosen
      isTar1Correct
      isTar2Correct
      isCorrect

      start
      isRepeat
      isSuccess
      isFailure
      isAbort
   end
   properties(SetAccess=protected)
      version = '0.1.0'
   end
   methods
      function self = Msup2(varargin)
         self = self@metadata.Trial;
         
         p = inputParser;
         p.KeepUnmatched= true;
         p.FunctionName = 'Msup2 constructor';
         p.addParamValue('trial',[],@(x) isscalar(x) && isnumeric(x));
         p.addParamValue('ruleBlockTrial',[],@(x) isscalar(x) && isnumeric(x));
         p.addParamValue('colorBlockTrial',[],@(x) isscalar(x) && isnumeric(x));
         p.addParamValue('currentRule',[],@ischar);
         p.addParamValue('currentColor',[],@ischar);
         p.addParamValue('rewardN_match',[],@(x) isscalar(x) && isnumeric(x));
         p.addParamValue('reward_match',[],@(x) isscalar(x) && isnumeric(x));
         p.addParamValue('rewardN_nonmatch',[],@(x) isscalar(x) && isnumeric(x));
         p.addParamValue('reward_nonmatch',[],@(x) isscalar(x) && isnumeric(x));
         p.addParamValue('posTar1',[],@(x) (numel(x)==2) && isnumeric(x));
         p.addParamValue('posTar2',[],@(x) (numel(x)==2) && isnumeric(x));
         p.addParamValue('posFix',[],@(x) (numel(x)==2) && isnumeric(x));
         p.addParamValue('colTar1',[],@(x) (numel(x)==3) && isnumeric(x));
         p.addParamValue('colTar2',[],@(x) (numel(x)==3) && isnumeric(x));
         p.addParamValue('colFeed',[],@(x) (numel(x)==3) && isnumeric(x));
         p.addParamValue('colFeedC',[],@(x) (numel(x)==3) && isnumeric(x));
         p.addParamValue('delay',[],@(x) isscalar(x) && isnumeric(x));
         p.addParamValue('overlap',[],@(x) isscalar(x) && isnumeric(x));
         p.addParamValue('stopTrial',[],@(x) isscalar(x));
         p.addParamValue('targetShapeMatchCue',[],@(x) isscalar(x));
         p.addParamValue('shrinkIncorrect',[],@(x) isscalar(x));
         p.addParamValue('reacquireProb',[],@(x) isscalar(x));
         p.addParamValue('reacquireProbFree',[],@(x) isscalar(x));
         p.addParamValue('incorrectVisible',[],@(x) isscalar(x));
         p.addParamValue('displayCounterfactual',[],@(x) isscalar(x));
         p.addParamValue('sync',[],@(x) isscalar(x) && isnumeric(x));
         p.addParamValue('isTar1Chosen',[],@(x) isscalar(x));
         p.addParamValue('isTar2Chosen',[],@(x) isscalar(x));
         p.addParamValue('isTar1Correct',[],@(x) isscalar(x));
         p.addParamValue('isTar2Correct',[],@(x) isscalar(x));
         p.addParamValue('isCorrect',[],@(x) isscalar(x));
         p.parse(varargin{:});
         par = p.Results;

         self.trial = par.trial;
         self.ruleBlockTrial = par.ruleBlockTrial;
         self.colorBlockTrial = par.colorBlockTrial;
         self.currentRule = par.currentRule;
         self.currentColor = par.currentColor;
         self.rewardN_match = par.rewardN_match;
         self.reward_match = par.reward_match;
         self.rewardN_nonmatch = par.rewardN_nonmatch;
         self.reward_nonmatch = par.reward_nonmatch;
         self.posTar1 = par.posTar1;
         self.posTar2 = par.posTar2;
         self.posFix = par.posFix;
         self.colTar1 = par.colTar1;
         self.colTar2 = par.colTar2;
         self.colFeed = par.colFeed;
         self.colFeedC = par.colFeedC;
         self.delay = par.delay;
         self.overlap = par.overlap;
         self.stopTrial = par.stopTrial;
         self.targetShapeMatchCue = par.targetShapeMatchCue;
         self.shrinkIncorrect = par.shrinkIncorrect;
         self.reacquireProb = par.reacquireProb;
         self.reacquireProbFree = par.reacquireProbFree;
         self.incorrectVisible = par.incorrectVisible;
         self.displayCounterfactual = par.displayCounterfactual;
         self.sync = par.sync;
         self.isTar1Chosen = par.isTar1Chosen;
         self.isTar2Chosen = par.isTar2Chosen;
         self.isTar1Correct = par.isTar1Correct;
         self.isTar2Correct = par.isTar2Correct;
         self.isCorrect = par.isCorrect;
      end
   end
end