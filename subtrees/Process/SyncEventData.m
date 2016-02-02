classdef (ConstructOnLoad) SyncEventData < event.EventData
   properties
      par
   end
   methods
      function eventData = SyncEventData(value)
         eventData.par = value;
      end
   end
end