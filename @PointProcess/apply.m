function output = windowFun(self,fun,nOpt,varargin)
% Apply a function to windowedTimes
%
% FUN should expect an array of event times. The output format of
% windowFun depends on three factors:
%   1) The number of outputs requested from FUN (NOPT)
%   2) The output format of FUN
%   3) Whether the PointProcess object is an array of objects
%
% If one output is requested from FUN (nOpt = 1, the default),
% then the expectation is that FUN returns scalar outputs that can
% be concatonated, and windowFun will return and array (see cellfun).
%   If more than one output is requested from FUN (nOpt > 1), then
% outputs will be collected in a cell array, with the elements
% corresponding to FUN outputs. Again, the expectation is that
% each of the outputs of FUN are scalars that can be concatonated.
%   If FUN does not return scalars, set 'UniformOutput' false, in
% which case, ARRAY is returned as a cell array. For the case of
% multiple outputs, this will be a cell array of cell arrays.
%
% For arrays of PointProcess objects, ARRAY is a cell array where
% each element is the output of windowFun called on the
% corresponding PointProcess object. Depending on 'UniformOutput',
% this can again be an array or a cell array.
%
% INPUTS
% fun      - Function handle
% nOpt     - # of outputs to return from FUN
% varargin - Additional arguments, the underlying call is to
%            cellfun, so varargin should be formatted accordingly
%
% EXAMPLE
% % process with different rates in two different windows
% spk = PointProcess('times',[rand(100,1) ; 1+rand(100,1)*10],'window',[0 1;1 10]);
% spk.raster('style','line');
%
% % Average inter-event interval in each window
% spk.windowFun(@(x) mean(diff(x)))
%
% % Maximum event time and index in each window
% spk.windowFun(@(x) max(x))
%
% % Return the maximum and it's index (nOpt = 2). Since both
% % outputs of MAX are scalar, the elements of RESULT are vectors,
% % one element corresponding to each window of SPK
% result = spk.windowFun(@(x) max(x),2)
%
% % Estimate a PSTH for each window. The outputs of GETPSTH are
% % not scalar, so result is a nested cell array, the outer cell
% % array corresponding to the different outputs of FUN, and the
% % inner cell array corresponding to outputs for each window of spk
% result = spk.windowFun(@(x) getPsth(x,0.025),2,'UniformOutput',false)
% figure; hold on
% plot(result{2}{1},result{1}{1},'r'); plot(result{2}{2},result{1}{2},'b')
%
% SEE ALSO
% cellfun

% TODO perhaps we should do a try/catch to automatically attempt to set
% uniformoutput false?
% Collection should coordinate how to handle the outputs of windowFun
% analysis method, need to handle the following situations
% 1) function applied to each element, and returned individually, eg. first
% spike time in each window, or the number of spikes in each window
% 2) function applied to groupings of elements, eg., psth

% first is easy, we just return big cell arrays full of stuff
% second is less obvious. Requires arranging windowedTimes across all
% elements into a format that the function expects. For consistency, we
% want a general format that can be passed around?
% how about the one for getPsth and plotRaster
if nargin < 3
   nOpt = 1;
end

if numel(self) == 1
   if nOpt == 1
      output = cellfun(fun,self.times,varargin{:});
   else
      [output{1:nOpt}] = cellfun(fun,self.times,varargin{:});
   end
else
   output = cell(size(self));
   for i = 1:numel(self)
      output{i} = apply(self(i),fun,nOpt,varargin{:});
   end
end
