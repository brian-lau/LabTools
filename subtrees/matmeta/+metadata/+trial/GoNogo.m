classdef GoNogo < metadata.Trial
   properties
      trial
      nTrial
      sync
      start
      isCorrect
      isOmission
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
         p.parse(varargin{:});
         par = p.Results;
         
         self.trial = par.trial;
         self.nTrial = par.nTrial;
         self.sync = par.sync;
         self.isCorrect = par.isCorrect;
         self.isOmission = par.isOmission;
      end
   end
end