classdef ECKEEGTrialPlot < handle
    
    properties
        Conditions
        Col_BG = [000, 000, 000];
        Col_FG = [240, 240, 240];
%         XAxis = ECKAxis('type', 'x')
%         yAxis = ECKAxis('type', 'y')
    end
    
    properties (SetAccess = private)
    end
    
    properties (Access = private)
        privState
        privWinPtr
        privScreenOpen 
        privScreenNumber
        privWindowSize
        privFullscreen
        privData
        privDataType
        privNumTrials
        privValid
        privError
        privTrial
        privWidth
        privHeight
        privPTBOldSyncTests
        privPTBOldWarningFlag
    end
    
    properties (Dependent)
        Data
        Trial
        ScreenNumber
        WindowSize 
        Fullscreen
    end
    
    properties (Dependent, SetAccess = private)
        State
        Error
%         WinPtr
    end
    
    methods 
        
        % consructor
        function obj = ECKEEGTrialPlot
            
            % disable sync tests and set PTB verbosity to minimum
            obj.privPTBOldSyncTests =...
                Screen('Preference', 'SkipSyncTests', 2);
            obj.privPTBOldWarningFlag =...
                Screen('Preference', 'SuppressAllWarnings', 1);
            
            % screen defaults
            obj.privScreenOpen = false;
            obj.privScreenNumber = max(Screen('screens'));
            if obj.privScreenNumber == 0
                % small window as only one screen
                obj.privWindowSize = round(...
                    Screen('Rect', obj.privScreenNumber) .* .3);
                obj.privFullscreen = false;
            else
                % fullscreen
                obj.privWindowSize = Screen('Rect', obj.privScreenNumber);
                obj.privFullscreen = true;
            end
                       
            % open screen
            obj.OpenScreen
        
        end
        
        % destructor
        function delete(obj)
            
            % close open screen
            if obj.privScreenOpen
                obj.CloseScreen
            end
            
           % reset PTB prefs
            Screen('Preference', 'SkipSyncTests', obj.privPTBOldSyncTests);
            Screen('Preference', 'SuppressAllWarnings',...
                obj.privPTBOldWarningFlag);
            
        end
        
        function CheckState(obj)
                
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
        
        function OpenScreen(obj)
            if obj.privScreenOpen
                error('Screen already open.')
            end
            if obj.privFullscreen
                fullscreenFlag = [];
                rect = Screen('Rect', obj.ScreenNumber);
            else
                rect = obj.privWindowSize;
                fullscreenFlag = kPsychGUIWindow;
            end
            obj.privWinPtr = Screen('OpenWindow', obj.privScreenNumber,...
                obj.Col_BG, rect, [], [], 8, [], fullscreenFlag);
            obj.privScreenOpen = true;
        end
        
        function CloseScreen(obj)
            if ~obj.privScreenOpen
                error('Screen is not open.')
            end
            Screen('Close', obj.privWinPtr);
            obj.privScreenOpen = false;
        end
        
        function ReopenScreen(obj)
            if obj.privScreenOpen
                obj.CloseScreen;
                obj.OpenScreen;
            end
        end
        
        function val = get.Error(obj)
            obj.CheckState
            val = obj.privError;
        end
                
        function val = get.ScreenNumber(obj)
            val = obj.privScreenNumber;
        end
        
        function set.ScreenNumber(obj, val)
            % check bounds
            screens = Screen('screens');
            if val > max(screens) || val < min(screens)
                error('ScreenNumber must be between %d and %d.',...
                    min(screens), max(screens))
            end
            obj.privScreenNumber = val;
            obj.ReopenScreen
        end
        
        function val = get.WindowSize(obj)
            val = obj.privWindowSize;
        end
        
        function set.WindowSize(obj, val)
            obj.privWindowSize = val;
            obj.ReopenScreen
        end
        
        function val = get.Fullscreen(obj)
            val = obj.privFullscreen;
        end
        
        function set.Fullscreen(obj, val)
            obj.privFullscreen = val;
            obj.ReopenScreen
        end
        
        function val = get.Data(obj)
            val = obj.privData;
        end
        
        function set.Data(obj, val)
            obj.privDataType = ft_datatype(val);
            switch obj.privDataType
                case 'raw'
                    obj.privNumTrials = length(val.Trial);
                    if obj.privTrial > obj.privNumTrials
                        obj.privTrial = obj.privNumTrials;
                    elseif isempty(obj.privTrial) || obj.privTrial < 1 
                        obj.privTrial = 1;
                    end
                otherwise
                    error('Unrecognised or unsupported data format.')
            end
        end                        
        
        function val = get.Trial(obj)
            % if not valid (implying possibly not data to enumerate trial
            % numbers against), throw an error
            if ~obj.privValid
                error('Cannot set Trial when State is not valid: \n%s',...
                    obj.Error);
            end
            val = obj.privTrial;
        end
        
        function set.Trial(obj, val)
            % if not valid (implying possibly not data to enumerate trial
            % numbers against), throw an error
            if ~obj.privValid
                error('Cannot set Trial when State is not valid: \n%s',...
                    obj.Error);
            end
            obj.privTrial = val;
        end            
        
    end
 
end