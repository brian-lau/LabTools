function [artifact,trial] = rejectArtifacts(s)

plotit = false;

data = s.convert2Fieldtrip();
%% Threshold artifacts
if 1
   trial.threshold = zeros(size(data.trial,2),numel(data.label));
   for i = 1:numel(s.labels)
      cfg = [];
      cfg.feedback = 'no';
      cfg.continuous = 'yes';
      cfg.trl = [data.sampleinfo , zeros(size(data.sampleinfo,1),1)];
      cfg.artfctdef.threshold.channel   = data.label{i};
      cfg.artfctdef.threshold.bpfilter  = 'yes';
      cfg.artfctdef.threshold.bpfreq    = [0.3 30];
      cfg.artfctdef.threshold.bpfiltord = 4;
      cfg.artfctdef.threshold.range     = 100;
      cfg.artfctdef.threshold.min       = -100;
      cfg.artfctdef.threshold.max       = 100;
      [cfg, artifact(i).threshold] = ft_artifact_threshold(cfg,data);
      if ~isempty(artifact(i).threshold)
         ind = find(ismember(cfg.trl(:,1:2),artifact(i).threshold,'rows'));
         trial.threshold(ind,i) = 1;
      end
   end
   tempcfg.artfctdef.threshold.artifact = cat(1,artifact.threshold);
end
%% Jump artifacts
if 1
   trial.jump = zeros(size(data.trial,2),numel(data.label));
   for i = 1:numel(s.labels)
      cfg = [];
      cfg.feedback = 'no';
      cfg.continuous = 'yes';
      % channel selection, cutoff and padding
      cfg.artfctdef.zvalue.channel    = data.label{i};
      cfg.artfctdef.zvalue.cutoff     = 20;
      cfg.artfctdef.zvalue.trlpadding = 0;
      cfg.artfctdef.zvalue.artpadding = 0;
      cfg.artfctdef.zvalue.fltpadding = 0;
      % algorithmic parameters
      cfg.artfctdef.zvalue.cumulative    = 'yes';
      cfg.artfctdef.zvalue.medianfilter  = 'yes';
      cfg.artfctdef.zvalue.medianfiltord = 9;
      cfg.artfctdef.zvalue.absdiff       = 'yes';
      % make the process interactive
      cfg.artfctdef.zvalue.interactive = 'no';
      [cfg, artifact(i).jump] = ft_artifact_zvalue(cfg,data);
      if ~isempty(artifact(i).jump)
         ind = find(ismember(data.sampleinfo,artifact(i).jump,'rows'));
         trial.jump(ind,i) = 1;
      end
   end
   tempcfg.artfctdef.jump.artifact = cat(1,artifact.jump);
end
%% Muscle artifacts
if 1
   trial.muscle = zeros(size(data.trial,2),numel(data.label));
   for i = 1:numel(s.labels)
      cfg = [];
      cfg.feedback = 'no';
      cfg.continuous = 'yes';
      % channel selection, cutoff and padding
      cfg.artfctdef.zvalue.channel     = data.label{i};
      cfg.artfctdef.zvalue.cutoff      = 6;
      cfg.artfctdef.zvalue.trlpadding  = 0;
      cfg.artfctdef.zvalue.fltpadding  = 0;
      cfg.artfctdef.zvalue.artpadding  = 0.1;
      % algorithmic parameters
      cfg.artfctdef.zvalue.bpfilter    = 'yes';
      cfg.artfctdef.zvalue.bpfreq      = [110 140];
      cfg.artfctdef.zvalue.bpfiltord   = 9;
      cfg.artfctdef.zvalue.bpfilttype  = 'but';
      cfg.artfctdef.zvalue.hilbert     = 'yes';
      cfg.artfctdef.zvalue.boxcar      = 0.2;
      % make the process interactive
      cfg.artfctdef.zvalue.interactive = 'no';
      [cfg, artifact(i).muscle] = ft_artifact_zvalue(cfg,data);
      if ~isempty(artifact(i).muscle)
         ind = find(ismember(data.sampleinfo,artifact(i).muscle,'rows'));
         trial.muscle(ind,i) = 1;
      end
   end
   tempcfg.artfctdef.muscle.artifact = cat(1,artifact.muscle);
end

if plotit
   cfg = [];
   cfg.layout = 'ordered';
   layout = ft_prepare_layout(cfg,data);
   cfg = tempcfg;
   cfg.viewmode = 'vertical';
   cfg.ylim = [-15 15];
   cfg.layout = layout;
   temp = ft_databrowser(cfg, data);
end