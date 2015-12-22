function obj = restrictByInfo(self,key,prop,value,logic)

if nargin < 5
   logic = 'and';
end

if ~iscell(key)
   key = {key};
end
if ~iscell(prop)
   prop = {prop};
end
if ~iscell(value)
   value = {value};
end

% Find all segments where key & prop exist
nQueries = numel(key);
bool = true(numel(self),nQueries);
for i = 1:nQueries
   q = linq(self);
   bool(:,i) = q.select(@(x) isKey(x.info,key{i}) ...
      && (isprop(x.info(key{i}),prop{i}) || isfield(x.info(key{i}),prop{i}))).toArray();
end
eligible = all(bool,2);

% Check value for each key & prop
match = true(q.count,nQueries);
for i = 1:nQueries
   q = linq(self(eligible));
   match(:,i) = q.select(@(x) x.info(key{i}).(prop{i}) == value{i}).toArray();
end

switch logic
   case {'and','all'}
      ind = all(match,2);
   case {'or','any'}
      ind = any(match,2);
end
temp = self(eligible);
obj = temp(ind);
% 
% if isnumeric(value) || islogical(value)
%    obj = q.where(@(x) isKey(x.info,key))...
%       .where(@(x) isprop(x.info(key),prop) || isfield(x.info(key),prop))...
%       .where(@(x) x.info(key).(prop) == value).toArray();
% else
%    obj = q.where(@(x) isKey(x.info,key))...
%       .where(@(x) isprop(x.info(key),prop) || isfield(x.info(key),prop))...
%       .where(@(x) strcmp(x.info(key).(prop),value)).toArray();
% end
