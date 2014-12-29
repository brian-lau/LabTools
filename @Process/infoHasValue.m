function bool = infoHasValue(self,value,varargin)
% Boolean for whether INFO dictionary has value
%
% It is possible to restrict to keys by passing in additional args
% self.doesInfoHaveValue(value,'keys',{cell array of keys})
bool = self.mapHasValue({self.info},value,varargin{:});
