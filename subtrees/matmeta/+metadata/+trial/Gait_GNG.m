classdef Gait_GNG < metadata.Trial
    properties
        
        patient
        task
        instruction
        trial
        nTrial
        medcondition
        run
        obs
        Cote
        t_Reaction
        t_APA
        APA_antpost
        APA_lateral
        StepWidth
        t_swing1
        t_DA
        t_swing2
        t_cycle_marche
        Longueur_pas
        V_swing1
        Vy_FO1
        t_VyFO1
        Vm
        t_Vm
        VML_absolue
        Freq_InitiationPas
        Cadence
        VZmin_APA
        V1
        V2
        Diff_V
        Freinage
        t_chute
        t_freinage
        t_V1
        t_V2
        
    end
    
    properties(SetAccess=protected)
        version = '0.1.0'
    end
    
    methods
        function self = Gait_GNG(varargin)
            self = self@metadata.Trial;
            p = inputParser;
            p.KeepUnmatched= true;
            p.FunctionName = 'Gait constructor';
            p.addParameter('patient',[],@(x) ischar(x));
            p.addParameter('task',[],@(x) ischar(x));
            p.addParameter('instruction',[],@(x) ischar(x));
            p.addParameter('trial',[],@(x) ischar(x));
            p.addParameter('nTrial',[],@(x) ischar(x));
            p.addParameter('medcondition',[],@(x) ischar(x));
            p.addParameter('run',[],@(x) ischar(x));
            p.addParameter('obs',[],@(x) ischar(x));
            p.addParameter('Cote',[],@(x) ischar(x));
            p.addParameter('t_Reaction',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('t_APA',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('APA_antpost',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('APA_lateral',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('StepWidth',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('t_swing1',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('t_DA',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('t_swing2',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('t_cycle_marche',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('Longueur_pas',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('V_swing1',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('Vy_FO1',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('t_VyFO1',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('Vm',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('t_Vm',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('VML_absolue',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('Freq_InitiationPas',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('Cadence',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('VZmin_APA',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('V1',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('V2',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('Diff_V',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('Freinage',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('t_chute',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('t_freinage',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('t_V1',[],@(x) isscalar(x) && isnumeric(x));
            p.addParameter('t_V2',[],@(x) isscalar(x) && isnumeric(x));
            p.parse(varargin{:});
            par = p.Results;
            
            self.patient = par.patient;
            self.task = par.task;
            self.type = par.instruction;
            self.trial = par.trial;
            self.nTrial = par.nTrial;
            self.medcondition = par.medcondition;
            self.run = par.run;
            self.obs = par.obs;
            self.Cote = par.Cote;
            self.t_Reaction = par.t_Reaction;
            self.t_APA = par.t_APA;
            self.APA_antpost = par.APA_antpost;
            self.APA_lateral = par.APA_lateral;
            self.StepWidth = par.StepWidth;
            self.t_swing1 = par.t_swing1;
            self.t_DA = par.t_DA;
            self.t_swing2 = par.t_swing2;
            self.t_cycle_marche = par.t_cycle_marche;
            self.Longueur_pas = par.Longueur_pas;
            self.V_swing1 = par.V_swing1;
            self.Vy_FO1 = par.Vy_FO1;
            self.t_VyFO1 = par.t_VyFO1;
            self.Vm = par.Vm;
            self.t_Vm = par.t_Vm;
            self.VML_absolue = par.VML_absolue;
            self.Freq_InitiationPas = par.Freq_InitiationPas;
            self.Cadence = par.Cadence;
            self.VZmin_APA = par.VZmin_APA;
            self.V1 = par.V1;
            self.V2 = par.V2;
            self.Diff_V = par.Diff_V;
            self.Freinage = par.Freinage;
            self.t_chute = par.t_chute;
            self.t_freinage = par.t_freinage;
            self.t_V1 = par.t_V1;
            self.t_V2 = par.t_V2;
            
        end
    end
end