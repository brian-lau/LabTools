% object array
% multiple windows
% arbitrary function_handle
% output policy (restrict to one event?)
% multiple event labels
function ev = find(self,varargin)

p = inputParser;
p.FunctionName = 'EventProcess find';
p.addParameter('eventType',[],@ischar);
p.addParameter('eventProp','name',@(x) ischar(x) || iscell(x));
p.addParameter('eventVal',[]);
p.addParameter('func',[],@(x) isa(x,'function_handle'));
p.addParameter('logic','or',@(x) any(strcmp(x,{'or' 'union' 'and' 'intersection' 'xor' 'setxor'})));
p.parse(varargin{:});
par = p.Results;

nObj = numel(self);
for i = 1:nObj
   ev(i) = findEach(self(i),par);
end

function ev = findEach(obj,par)

events = obj.values{1};
if isempty(events)
   ev = obj.nullEvent;
   return;
end

eventTypeInd = [];
if ~isempty(par.eventType) % requires full event match (ignores eventProp/Val)
   eventTypeInd = strcmpi(arrayfun(@(x) class(x),events,'uni',0),par.eventType);
end

eventPropInd = [];
if ~isempty(par.eventVal)
   % labels are heterogenous, so we filter out elements that do not possess
   % the property of interest (treated as false)
   matchProp = find(isprop(events,par.eventProp));
   temp = events(matchProp);
   
   % labelProp values are unconstrained, so we filter out possibilities
   % where they differ from eventVal in type
   v = {temp.(par.eventProp)};
   types = cellfun(@(x) class(x),v,'uni',0);
   match = find(strcmp(types,class(par.eventVal)));
   
   if isnumeric(par.eventVal)
      I = find(ismember([v{match}],par.eventVal));
   elseif ischar(par.eventVal)
      I = find(ismember(v(match),par.eventVal));
   else
      try
         I = find(v(match) == par.eventVal);
      catch
         error('help!');
      end
   end

   % Reinsert the matching indices for the reduced subset back into full index
   eventPropInd = false(1,obj.n);
   eventPropInd(matchProp(match(I))) = true;
   eventPropInd = find(eventPropInd);
end

funcInd = [];
if ~isempty(par.func)
   % TODO cell array of function handles, allow multiple arbitrary crit
   funcInd = find(arrayfun(par.func,events,'ErrorHandler',@errorhandler));
end

baseInd = 1:numel(events);
selection = [];
switch lower(par.logic)
   case {'or' 'union'}
      selection = unique(vertcat(eventTypeInd(:),eventPropInd(:),funcInd(:)));
      %selection = unionm(eventTypeInd,eventPropInd,funcInd);
   case {'and' 'intersection'}
      if ~isempty(eventTypeInd)
         selection = eventTypeInd;
      else
         selection = baseInd;
      end
      if ~isempty(eventPropInd)
         selection = intersect(selection,eventPropInd);
      end
      if ~isempty(funcInd)
         selection = intersect(selection,funcInd);
      end
   case {'xor' 'setxor'}
      selection = setxor(baseInd,unionm(eventTypeInd,eventPropInd,funcInd));
end

if isempty(selection)
   ev = obj.nullEvent;
else
   ev = events(selection);
end

%%
function result = errorhandler(err,varargin)
if strcmp(err.identifier,'MATLAB:noSuchMethodOrField');
   result = false;
else
   err = MException(err.identifier,err.message);
   cause = MException('EventProcess:find:func',...
      'Problem in function handle.');
   err = addCause(err,cause);
   throw(err);
end
