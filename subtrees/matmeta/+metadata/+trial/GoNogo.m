classdef GoNogo < metadata.Trial
   properties
      trial
      nTrial
      sync
      start
      isCorrect    % Correct Go or NoGo trial
      isOmission   % Miss
      isCommission % Go on NoGo trial
      isFA         % Go before Cue
   end
   properties(SetAccess=protected)
      version = '0.1.0'
   end
   methods
      function self = GoNogo(varargin)
         self = self@metadata.Trial;
         
         p = inputParser;
         p.KeepUnmatched= true;
         p.FunctionName = 'GoNogo constructor';
         p.addParameter('trial',[],@(x) ischar(x));
         p.addParameter('nTrial',[],@(x) isscalar(x) && isnumeric(x));
         p.addParameter('sync',[],@(x) isscalar(x) && isnumeric(x));
         p.addParameter('isCorrect',[],@(x) isscalar(x));
         p.addParameter('isOmission',[],@(x) isscalar(x));
         p.addParameter('isCommission',[],@(x) isscalar(x));
         p.addParameter('isFA',[],@(x) isscalar(x));
         p.parse(varargin{:});
         par = p.Results;
         
         self.trial = par.trial;
         self.nTrial = par.nTrial;
         self.sync = par.sync;
         self.isCorrect = par.isCorrect;
         self.isOmission = par.isOmission;
         self.isCommission = par.isCommission;
         self.isFA = par.isFA;
      end
   end
end