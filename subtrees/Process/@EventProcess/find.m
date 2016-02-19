% multiple windows
% multiple event labels
function ev = find(self,varargin)

p = inputParser;
p.FunctionName = 'EventProcess find';
p.addParameter('eventType',[],@ischar);
p.addParameter('eventProp','name',@(x) ischar(x) || iscell(x));
p.addParameter('eventVal',[]);
p.addParameter('func',[],@(x) isa(x,'function_handle'));
p.addParameter('logic','or',@(x) any(strcmp(x,{'or' 'union' 'and' 'intersection' 'xor' 'setxor'})));
p.addParameter('policy','first',@(x) any(strcmp(x,{'first' 'last' 'all'})));
p.parse(varargin{:});
par = p.Results;

nObj = numel(self);
for i = 1:nObj
   switch lower(par.policy)
      case {'first' 'last'}
         ev(i) = findEach(self(i),par);
      case {'all'}
         ev{i} = findEach(self(i),par);
   end
end

%%
function result = findEach(obj,par)

events = obj.values{1};
nev = numel(events);
if isempty(events)
   result = obj.nullEvent;
   return;
end

if ~isempty(par.eventType) % requires full event match (ignores eventProp/Val)
   eventTypeInd = strcmpi(arrayfun(@(x) class(x),events,'uni',0),par.eventType);
else
   eventTypeInd = false(nev,1);
end

if ~isempty(par.eventVal)
   if isnumeric(par.eventVal)
      v = arrayfun(@(x) ismember(x.(par.eventProp),par.eventVal),events,'uni',0,'ErrorHandler',@valErrorHandler);
   elseif ischar(par.eventVal)
      v = arrayfun(@(x) strcmp(x.(par.eventProp),par.eventVal),events,'uni',0,'ErrorHandler',@valErrorHandler);
   else
      % works for handles
      v = arrayfun(@(x) x.(par.eventProp)==par.eventVal,events,'uni',0,'ErrorHandler',@valErrorHandler);
   end
   eventPropInd = vertcat(v{:});
else
   eventPropInd = false(nev,1);
end

if ~isempty(par.func)
   % TODO cell array of function handles, allow multiple arbitrary crit
   funcInd = arrayfun(par.func,events,'ErrorHandler',@funcErrorHandler);
else
   funcInd = false(nev,1);
end

switch lower(par.logic)
   case {'or' 'union'}
      selection = eventTypeInd | eventPropInd | funcInd;
   case {'and' 'intersection'}
      if isempty(par.eventType)
         eventTypeInd = true(nev,1);
      end
      if isempty(par.eventVal)
         eventPropInd = true(nev,1);
      end
      if isempty(par.func)
         funcInd = true(nev,1);
      end
      selection = eventTypeInd & eventPropInd & funcInd;
   case {'xor' 'setxor'}
      selection = sum([eventTypeInd,eventPropInd,funcInd],2) == 1;
   otherwise
      selection = false(nev,1);
end

if all(~selection)
   ev = obj.nullEvent;
else
   ev = events(selection);
end

switch lower(par.policy)
   case {'first'}
      result = ev(1);
   case {'last'}
      result = ev(end);
   case {'all'}
      result = ev;
end

%%
function result = funcErrorHandler(err,varargin)
if strcmp(err.identifier,'MATLAB:noSuchMethodOrField');
   result = false;
else
   err = MException(err.identifier,err.message);
   cause = MException('EventProcess:find:func',...
      'Problem in function handle.');
   err = addCause(err,cause);
   throw(err);
end

function result = valErrorHandler(err,varargin)
if strcmp(err.identifier,'MATLAB:noSuchMethodOrField');
   result = false;
else
   err = MException(err.identifier,err.message);
   cause = MException('EventProcess:find:eventProp',...
      'Problem in eventProp/Val pair.');
   err = addCause(err,cause);
   throw(err);
end