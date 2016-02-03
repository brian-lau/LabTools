classdef Msup < metadata.Trial
   properties
      trial
      blockTrial
      nTrial
      current
      posTar
      posDis
      posFix
      colTar
      colDis
      delay
      overlap
      stopTrial
      sync
      start
      isCorrect
      isRepeat
      isSuccess
      isFailure
      isAbort
   end
   properties(SetAccess=protected)
      version = '0.1.0'
   end
   methods
      function self = Msup(varargin)
         self = self@metadata.Trial;
         
         p = inputParser;
         p.KeepUnmatched= true;
         p.FunctionName = 'Msup constructor';
         p.addParameter('trial',[],@(x) isscalar(x) && isnumeric(x));
         p.addParameter('blockTrial',[],@(x) isscalar(x) && isnumeric(x));
         p.addParameter('nTrial',[],@(x) isscalar(x) && isnumeric(x));
         p.addParameter('current',[],@ischar);
         p.addParameter('posTar',[],@(x) (numel(x)==2) && isnumeric(x));
         p.addParameter('posDis',[],@(x) (numel(x)==2) && isnumeric(x));
         p.addParameter('posFix',[],@(x) (numel(x)==2) && isnumeric(x));
         p.addParameter('colTar',[],@(x) (numel(x)==3) && isnumeric(x));
         p.addParameter('colDis',[],@(x) (numel(x)==3) && isnumeric(x));
         p.addParameter('delay',[],@(x) isscalar(x) && isnumeric(x));
         p.addParameter('overlap',[],@(x) isscalar(x) && isnumeric(x));
         p.addParameter('stopTrial',[],@(x) isscalar(x));
         p.addParameter('sync',[],@(x) isscalar(x) && isnumeric(x));
         p.addParameter('isCorrect',[],@(x) isscalar(x));
         p.parse(varargin{:});
         par = p.Results;
         
         self.trial = par.trial;
         self.blockTrial = par.blockTrial;
         self.nTrial = par.nTrial;
         self.current = par.current;
         self.posTar = par.posTar;
         self.posDis = par.posDis;
         self.posFix = par.posFix;
         self.colTar = par.colTar;
         self.colDis = par.colDis;
         self.delay = par.delay;
         self.overlap = par.overlap;
         self.stopTrial = par.stopTrial;
         self.sync = par.sync;
         self.isCorrect = par.isCorrect;
      end
   end
end