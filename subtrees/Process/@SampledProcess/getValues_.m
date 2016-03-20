% Return original values, subset by current selection
function values_ = getValues_(self)

values_ = {self.values_{1}(:,self.selection_)};