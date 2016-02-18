% object array
% multiple windows
% arbitrary function_handle
function ev = find(self,varargin)

p = inputParser;
p.KeepUnmatched= true;
p.FunctionName = 'EventProcess find';
p.addParameter('eventType',[],@ischar);
p.addParameter('eventProp','name',@(x) ischar(x) || iscell(x));
p.addParameter('eventVal',[]);
p.addParameter('logic','or',@(x) any(strcmp(x,{'or' 'union' 'and' 'intersection' 'xor' 'setxor'})));
p.parse(varargin{:});
par = p.Results;

args = p.Unmatched;

events = self.values{1};
if isempty(events)
   ev = self.nullEvent;
   return;
end

eventTypeInd = [];
if ~isempty(par.eventType) % requires full event match (ignores eventProp/Val)
   eventTypeInd = strcmpi(arrayfun(@(x) class(x),events,'uni',0),par.eventType);
end

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
   eventPropInd = false(1,self.n);
   eventPropInd(matchProp(match(I))) = true;
   eventPropInd = find(eventPropInd);
end
   
% switch lower(par.logic)
%    case {'or' 'union'}
      selection = unionm(eventTypeInd,eventPropInd);
%    case {'and' 'intersection'}
%       if ~isempty(par.index)
%          selection = indexInd;
%       else
%          selection = baseInd;
%       end
%       if ~isempty(par.label)
%          selection = intersect(selection,labelInd);
%       end
%       if ~isempty(par.quality)
%          selection = intersect(selection,qualityInd);
%       end
%    case {'xor' 'setxor'}
%       selection = setxor(baseInd,unionm(indexInd,labelInd,qualityInd));
% end

if isempty(selection)
   ev = self.nullEvent;
else
   ev = events(selection);
end

% keyboard
% query = linq(self.values{1});
% fn = fieldnames(args);
% for i = 1:numel(fn)
%    if query.count>0
%       if isa(args.(fn{i}),'function_handle')
%          % This must evaluate to a boolean
%          query.where(args.(fn{i}));
%       elseif ischar(args.(fn{i}))
%          try
%             query.where(@(x) strcmp(x.(fn{i}),args.(fn{i})));
%          catch
%          end
%          %                   query.where(@(x) isprop(x,fn{i}))...
%          %                        .where(@(x) strcmp(x.(fn{i}),args.(fn{i})));
%       else
%          % attempt equality
%          query.where(@(x) x.(fn{i})==args.(fn{i}));
%       end
%    end
% end
% 
% if query.count > 0
%    ev = query.toArray();
% else
%    ev = self.nullEvent;
% end
