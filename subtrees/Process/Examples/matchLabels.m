function ep = matchLabels(data,artifacts)

if numel(data) > 1
   %keyboard;
   assert(numel(data)==numel(artifacts),'number of artifacts must match')
   for i = 1:numel(data)
      ep(i) = matchLabels(data(i),artifacts(i));
   end
   return
end

labels = data.labels;
times = artifacts.times{1};
values = artifacts.values{1};

if numel(values) > 0
   for i = 1:numel(values)
      for j = 1:numel(values(i).labels)
         ind = strcmp({labels.name},values(i).labels(j).name);
         if sum(ind) == 1
            ind2(j) = find(ind);
         else
            error('no match?');
         end
         %values(i).labels(j) = labels(ind);
      end
      values(i).labels = labels(sort(ind2));
      clear ind2;
   end
   
   ep = EventProcess('events',values,'times',times,'tStart',data.tStart,'tEnd',data.tEnd);
   assert(all(all(ep.times{1} == artifacts.times{1})),'mismatch times');
   
   values2 = ep.values{1};
   assert(numel(values2)==numel(values),'incorrect values');
   
   for i = 1:numel(values2)
      names = intersect({values(i).labels.name},{values2(i).labels.name});
      assert(numel(names) == numel(values(i).labels),'mismatch');
   end
else
   ep = artifacts;
end