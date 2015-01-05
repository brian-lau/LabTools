% Boolean for whether Process info dictionary has value
%
% It is possible to restrict to keys by passing in additional args
% self.infoHasValue(value,'keys',{cell array of keys})

function bool = infoHasValue(self,value,varargin)

bool = map.mapHasValue({self.info},value,varargin{:});
