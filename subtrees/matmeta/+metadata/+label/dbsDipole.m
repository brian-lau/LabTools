% 
classdef dbsDipole < metadata.Label
   properties
      side
      contacts
      coordinateSystem
      x
      y
      z
   end
   methods
      function self = dbsDipole(varargin)

         if (nargin == 1)
            x = varargin{1};
            if ischar(x) && (numel(x)==3)
               varargin{1} = 'name';
               varargin{2} = x;
               varargin{3} = 'side';
               varargin{4} = x(3);
               varargin{5} = 'contacts';
               varargin{6} = x(1:2);
            end
         end

         self = self@metadata.Label(varargin{:});
         if nargin == 0
            return;
         end
         
         p = inputParser;
         p.KeepUnmatched= true;
         p.FunctionName = 'dbsDipole constructor';
         p.addParameter('side','r',@ischar);
         p.addParameter('contacts','',@(x) ischar(x) || isnumeric(x));
         p.addParameter('coordinateSystem','',@ischar);
         p.addParameter('x',[],@(x) isnumeric(x) && isscalar(x));
         p.addParameter('y',[],@(x) isnumeric(x) && isscalar(x));
         p.addParameter('z',{},@(x) isnumeric(x) && isscalar(x));
         p.parse(varargin{:});
         par = p.Results;
         
         self.side = par.side;
         self.contacts = par.contacts;
         defaultColor(self);
      end
      
      function set.side(self,side)
         assert(ischar(side),'Side must be a string');
         switch lower(side)
            case {'l' 'g'}
               self.side = 'left';
            case {'r' 'd'}
               self.side = 'right';
            otherwise
               error('invalid side');
         end
      end
      
      function set.contacts(self,contacts)
         if ischar(contacts)
            assert(numel(contacts)==2,'Must specify two contacts');
            contacts = [str2num(contacts(1)) str2num(contacts(2))];
         else
            assert(isnumeric(contacts) && (numel(contacts)==2),...
               'Must specify two contacts, each between 0 and 3');
         end
         if all(ismember(contacts,[0 1 2 3]))
            self.contacts = contacts(:)';
         end
      end
      
      function defaultColor(self)
         if strcmp(self.side,'left') && all(self.contacts==[0 1])
            self.color = [189 215 231]/255;
         elseif strcmp(self.side,'left') && all(self.contacts==[1 2])
            self.color = [107 174 214]/255;
         elseif strcmp(self.side,'left') && all(self.contacts==[2 3])
            self.color = [33 113 181]/255;
         elseif strcmp(self.side,'right') && all(self.contacts==[0 1])
            self.color = [253 190 133]/255;
         elseif strcmp(self.side,'right') && all(self.contacts==[1 2])
            self.color = [253 141 60]/255;
         elseif strcmp(self.side,'right') && all(self.contacts==[2 3])
            self.color = [217 71 1]/255;
         end
      end
      
   end
end