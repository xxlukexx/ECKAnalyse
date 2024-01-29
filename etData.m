classdef etData 
    
    properties
        
        MainBuffer
        TimeBuffer
        EventBuffer
        FixationBuffer
        Label='UNLABELLED'
        
    end
    
    properties (Dependent)
        
        % shortcuts for buffers
        mb
        tb
        eb
        fb
        
        NumData
        
    end
    
    properties (Dependent, SetAccess = private)
        
        % time vectors
        Time
        TimeFormatted
        
    end
    
    methods
        
        %% CONSTRUCTOR / DESTRUCTOR
        
        function obj = etData(varargin)
            
            % pass input arguments to AddData method. This is the same way
            % that we add data at any time. In this case, it is simply the
            % first time, as it happens in the constructor.
            
            obj = obj.AddData(varargin{:});
            
        end
        
        function delete(obj)
                    
        end
        
        %% DATA
        
        function obj = AddData(obj, varargin)
            
            % temp variables
            mbTmp = [];
            tbTmp = [];
            ebTmp = [];
            fbTmp = [];
            
            if nargin == 2
                
                % assume ECKData
                if ~isa(varargin{1}, 'ECKData')
                    error('Single input argument must be ECKData (or not specified).')
                else
                    
                    % get buffers
                    mbTmp = varargin{1}.MainBuffer;
                    tbTmp = varargin{1}.TimeBuffer;
                    ebTmp = varargin{1}.EventBuffer;
                    
                    % if available, get fixation buffer
                    if isprop(obj, 'FixBuffer')
                        fbTmp = varargin{1}.FixBuffer;
                    end
                    
                end
                
            elseif nargin >= 3
                
                % assume mb, tb
                mbTmp = varargin{1};
                tbTmp = varargin{2};
                
            end
            
            if nargin == 4
                % assume also eb
                ebTmp = varargin{3};
            end
                
            if nargin == 5
                % assume also fb
                fbTmp = varargin{4};
            end            
            
            % check that main and time buffers are the same length
            if size(mbTmp, 1) ~= size(tbTmp, 1)
                error('MainBuffer and TimeBuffer must be the same length.')
            end
            
            % if existing data is present, check that the size of the new
            % data matches the size of the old data
            if obj.NumData >= 1
                
                % check main buffer size
                if all(size(mbTmp) ~= size(obj.mb))
                    error('Cannot add data of a different length to existing data.')
                end
                
                % check time buffer size
                if all(size(tbTmp, 1) ~= size(obj.tb, 1))
                    error('Cannot add data of a different length to existing data.')
                end
                
                % check event buffer size
                if all(size(ebTmp, 1) ~= size(obj.eb, 1))
                    error('Cannot add data of a different length to existing data.')
                end
                
            end
            
            % add the data to the end of the third dimension of the
            % existing data
            obj.mb = cat(3, obj.mb, mbTmp);
            obj.tb = cat(3, obj.tb, tbTmp);
            if ~isempty(ebTmp), obj.eb = cat(3, obj.eb, ebTmp); end
            if ~isempty(fbTmp), obj.fb = cat(3, obj.fb, fbTmp); end
            
        end
        
        %% GET/SET
        
        % mb
        function obj = set.mb(obj, val)
            
            obj.MainBuffer = val;
            
        end
        
        function val = get.mb(obj)
            
            val = obj.MainBuffer;
            
        end
        
        % tb
        function obj = set.tb(obj, val)
            
            obj.TimeBuffer = val;
            
        end
        
        function val = get.tb(obj)
            
            val = obj.TimeBuffer;
            
        end
        
        % eb
        function obj = set.eb(obj, val)
            
            obj.EventBuffer = val;
            
        end
        
        function val = get.eb(obj)
            
            val = obj.EventBuffer;
            
        end
        
        % fb
        function obj = set.fb(obj, val)
            
            obj.FixationBuffer = val;
            
        end
        
        function val = get.fb(obj)
            
            val = obj.FixationBuffer;
            
        end
        
        % number of datasets
        function val = get.NumData(obj)
            
            if isempty(obj.mb)
                val = 0;
            else
                val = size(obj.mb, 3);
            end
            
        end
        
        % time vector
        function val = get.Time(obj)
            
            % if no tb is available, return
            if isempty(obj.tb)
                val = [];
                return
            end
            
            timeZeroed = obj.tb(:, 1) - obj.tb(1, 1);
            val = double(timeZeroed) / 1e6;
            
        end
        
%         % formatted time vector
%         function val = get.TimeFormatted(obj)
%             
%            % if no tb is available, return
%             if isempty(obj.Time)
%                 val = [];
%                 return
%             end
%             
%             dayFraction = obj.Time / 86400;
%             val = datestr(dayFraction, 'HH.MM.SS.FFF');
%            
%         end
        
    end
    
%     methods (Access = private)
%         
%         function [obj, timeVector, timeMax] = calculateTimes(obj)
%             
% 
%         end            
%         
%     end
    
end