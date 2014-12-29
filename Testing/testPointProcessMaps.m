events(1) = pointProcess('name','events','times',[0 1 10 20]./10,...
   'infoKeys',{'bears' 'dogs' 'hyenas'},'info',{true false false},...
   'map',{'start' 'cue' 'start' 'attend in'});

events(2) = pointProcess('name','events','times',[0 1 10 20]./10,...
   'infoKeys',{'lions' 'tigers' 'cats'},'info',{true true true},...
   'map',{'start' 'cue' 'start' 'attend out'});


events.doesInfoHaveKey('cats')
events.doesInfoHaveKey('dogs')
events.doesInfoHaveKey('monkeys')

events.doesInfoHaveValue(true)
events.doesInfoHaveValue(false)
events.doesInfoHaveValue(false,'keys',{'dogs' 'hyenas'})
events.doesInfoHaveValue(true,'keys',{'cats'})

events.doesMapHaveValue('attend out')
events.doesMapHaveValue('attend in')

tic;
for i = 1:1000
   events.doesInfoHaveKey('cats');
   events.doesInfoHaveKey('dogs');
   events.doesInfoHaveKey('monkeys');
   
   events.doesInfoHaveValue(true);
   events.doesInfoHaveValue(false);
   events.doesInfoHaveValue(false,'keys',{'dogs' 'hyenas'});
   events.doesInfoHaveValue(true,'keys',{'cats'});
   
   events.doesMapHaveValue('attend out');
   events.doesMapHaveValue('attend in');
end
toc


% 
% events = pointProcess('name','events','times',[0 1 10 20]./10,'marks',{'start' 'cue' 'start' 'start'})
% spk = pointProcess('name','neuron','times',[0:20]./10)
% 
% getMarkKeys (selectByValue)
% getMarkTimes (selectByValues)
%    return times associated with marks that have these values
%    logic = and, or
%    values = 'object' 'numeric value' 'string'
% getMarkTimes (selectByKeys)
% 
% setMarkKeys