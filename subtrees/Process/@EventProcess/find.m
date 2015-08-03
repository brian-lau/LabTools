function ev = find(self,varargin)

p = inputParser;
p.KeepUnmatched= true;
p.FunctionName = 'EventProcess find';
p.parse(varargin{:});
args = p.Unmatched;

query = linq(self.values{1});
fn = fieldnames(args);
for i = 1:numel(fn)
   if query.count>0
      if isa(args.(fn{i}),'function_handle')
         % This must evaluate to a boolean
         query.where(args.(fn{i}));
      elseif ischar(args.(fn{i}))
         try
            query.where(@(x) strcmp(x.(fn{i}),args.(fn{i})));
         catch
         end
         %                   query.where(@(x) isprop(x,fn{i}))...
         %                        .where(@(x) strcmp(x.(fn{i}),args.(fn{i})));
      else
         % attempt equality
         query.where(@(x) x.(fn{i})==args.(fn{i}));
      end
   end
end

if query.count > 0
   ev = query.toArray();
else
   ev = self.nullEvent;
end
