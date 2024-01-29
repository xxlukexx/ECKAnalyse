classdef ECKERPPlotter < handle
    
    properties
        WinPtr
        Position
        Data
        Conditions
        XAxis = ECKAxis('type', 'x')
        yAxis = ECKAxis('type', 'y')
    end
    
    properties (Access = private)
        privState
        privValid
        privError
        privWidth
        privHeight
    end
    
    properties (Dependent)
        Error
    end
    
    methods 
        
        % consructor
        function obj = ECKERPPlotter
                       
        
        end
        
        function CheckState(obj)
            
            % check for validly formed WinPtr
            if ~isempty(obj.WinPtr) && isnumeric(obj.WinPtr) &&...
                    obj.WinPtr < 0;
                val_WinPtr = true;
            else
                obj.privError = 'Invalid or missing WinPtr';
            end
                
            % check for validly formed Position
            if ~isempty(obj.Position) && isvector(obj.Position) &&...
                    length(obj.Position) == 4 
                
                % check for impossible coords
                if any(obj.Position < 0)
                    obj.privError = 'At least one position coord < 0';
                elseif obj.Position(1) > obj.Position(3)
                    obj.privError = 'x1 > x2';
                elseif obj.Position(2) > obj.Position(4)
                    obj.privError = 'y1 > y2';
                end
                
                val_Position = true;
                obj.privWidth = obj.Position(3) - obj.Position(1);
                obj.privHeight = obj.Position(4) - obj.Position(2);
                
            else
                val_Position = false;
            end
                
            % check data - to be written
            val_Data = true;
            
            % check conditions - to be written
            val_Conditions = true;
            
            obj.privValid = val_WinPtr && val_Position && val_Data &&...
                val_Conditions;
            
            if P.privValid 
                obj.privState = 'BLANK';
            else
                obj.privState = 'INVALID';
            end
            
        end
        
        % get/set
        function set.WinPtr(obj, ~)
            obj.CheckState
        end
        
        function val = get.Error(obj)
            obj.CheckState
            val = obj.privError;
        end
            
        
    end
        
        
    
    
    
    
end