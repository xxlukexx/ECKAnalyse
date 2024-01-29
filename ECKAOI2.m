% 20170626 to-do
% - sort out aspect ratios


classdef ECKAOI2 < handle
    
    properties 
        Name
        Colour = [255, 0, 255]
        OnsetTime = 0
        OffsetTime = inf
        MaskPath
        MaskWinPtr
        Visible = true;
    end
    
    properties (Dependent)
        Rect
    end
    
    properties (Dependent, SetAccess = private)
        Type 
        ColourOnDefault
    end
    
    properties (Access = private)
        privValid = false
        privType = 'RECT';
        privRect = [0, 0, 1, 1]
        privMaskImg
        privMaskImgTexPtr
        privMaskWinPtr
        privMaskMovPtr
        privMaskMovOpen = false
        privMaskMovDur
        privMaskMovFPS
        privMaskW
        privMaskH
        privMaskMovFrames
        privMaskCache
        privColourOnDefault = true
    end
    
    methods
        
        function delete(obj, varargin)
            if obj.privMaskMovOpen
                try
                    Screen('CloseMovie', obj.privMaskMovPtr);
                end
            end
        end
        
        function res = Score(obj, t, x, y)  
            % Key 
            %
            % 0     -   not in AOI
            % 1     -   in AOI
            % 2     -   AOI not active
            % 3     -   missing data
            
            obj.CheckValid
            if ~obj.privValid
                error('AOI not in a valid state to be scored.')
            end
            
            % get samples when aoi was active
            aoiOn = t >= obj.OnsetTime & t < obj.OffsetTime;
            
            % preallocate output
            numData = size(x, 1);
            res = nan(numData, length(t));
            numFrames = length(t);
            
            % get valid flags
            val = ~isnan(x) & ~isnan(y);
            
            % different methods for each AOI type
            switch obj.privType
                case {'DYNAMIC MASK', 'STATIC MASK'}
                    if strcmpi(obj.privType, 'DYNAMIC MASK')
                        
                        warning('THIS NEEDS CHECKING FOR IN AOI/AOI ON/MISSING!')
                        
                        % check the requested times against the duration of the
                        % AOI movie
                        if any(t > obj.privMaskMovDur)
                            numFrames =...
                                find(t > obj.privMaskMovDur, 1, 'first') - 1;
                        end
                    end
                    
                    % convert normalized coords to pixels. change any 0s to 1s
                    w               = obj.privMaskW;
                    h               = obj.privMaskH;
                    xf              = round(x * w);     % x pixels
                    xf(xf == 0)     = 1;
                    yf              = round(y * h);     % y pixels
                    yf(yf == 0) 	= 1;
                    res             = zeros(size(x));   % results
                    for f = 1:numFrames
                        
                        if aoiOn(f)
                            % convert x, y coords to linear indices 
                            idx = sub2ind([h, w], yf(:, f), xf(:, f));     

                            % store indices if NaNs (missing samples of data).
                            % These can't be used for a pixel lookup, so we replace
                            % them with ones temporarily, and then put NaNs back
                            % after the lookup
                            nanIdx = isnan(idx);
                            idx(nanIdx) = 1;    

                            % get AOI as image, keep just red channel (since this
                            % is a luminance/binary image, all colour channels have
                            % the same data in them). Convert image to logical. 
                            frameTime = t(f);
                            [suc, img] = obj.GetImage(frameTime);
                            if ~suc
                                warning('Could not read AOI image from video: %s, %d.',...
                                    obj.Name, f)
                                continue
                            end
                            img = double(img(:, :, 1));
                            img(img > 0) = 1;   

                            % look up pixel values at each x, y coords, put back
                            % NaNs
                            pxValues            = img(idx);
                            pxValues(nanIdx)    = 3;
                            res(:, f)           = pxValues;
                        else
                            res(:, f)           = 2;
                        end
                        
                    end
                    
                case 'RECT'
                    
                    % calculate samples in AOI
                    inAOI =...
                        x >= obj.privRect(1) &...
                        y >= obj.privRect(2) &...
                        x <= obj.privRect(3) &...
                        y <= obj.privRect(4);
                    
                    % code
                    res             = zeros(size(inAOI));   % not in AOI
                    res(~val)       = 3;                    % missing
                    res(inAOI)      = 1;                    % in AOI
                    res(:, ~aoiOn)  = 2;                    % AOI off
                    
                otherwise
                    error('Not yet implemented.')
            end  
        end
        
        function [success, framePtr] = GetFrame(obj, time)
            switch obj.privType
                case 'DYNAMIC MASK'
                    if ~obj.privMaskMovOpen
        %                 fprintf(2, 'Movie not open, cannot get frame.')
                        success = false;
                        framePtr = [];
                        return
                    end
%                     if time >= obj.privMaskMovDur - (1 / obj.privMaskMovFPS)
                    if obj.privMaskMovDur - time <= (1 / obj.privMaskMovFPS)
                        fprintf(2, 'Time index out of bounds.')
                        success = false;
                        framePtr = [];
                        return
                    end
                    fprintf('Movie: %s | time: %.4f\n', obj.MaskPath, time);
                    Screen('SetMovieTimeIndex', obj.privMaskMovPtr, time);
                    [framePtr, timeReturned] = Screen('GetMovieImage',...
                        obj.MaskWinPtr, obj.privMaskMovPtr);
                    success = timeReturned - time <= .2;
                case 'STATIC MASK'
                    success = true;
                    framePtr = obj.privMaskImgTexPtr;
                otherwise
                    error('Cannot get a frame from the current AOI type (must be STATIC or DYNAMIC MASK)')
            end
        end
        
        function [success, img] = GetImage(obj, time)
            success = false;
            obj.CheckValid
            if ~obj.privValid
                error('Mask not in a valid state.')
            end
            switch obj.privType
                case 'RECT'
                    error('Cannot get an image from an AOI of type RECT.')
                case 'DYNAMIC MASK'
                    [success, framePtr] = obj.GetFrame(time);
                    success = success && ~isempty(framePtr) && framePtr >= 0;
                    if success
                        img = Screen('GetImage', framePtr, [], [], [], 1);
                    else
                        img = [];
                    end
                case 'STATIC MASK'
                    img = obj.privMaskImg;
                    success = true;
            end
        end

        function CheckValid(obj)
            valid = false;
            switch obj.Type
                case 'DYNAMIC MASK'
                    obj.privRect = [];
                    valid = valid || ~isempty(obj.MaskPath);
                    valid = valid || exist(obj.MaskPath, 'file');
                    valid = valid || ~isempty(obj.MaskWinPtr);
                    valid = valid || obj.privMaskMovOpen;
                case 'STATIC MASK'
                    valid = valid || ~isempty(obj.privMaskImg);
                case 'RECT'
                    if isempty(obj.Rect), obj.privRect = [0, 0, 1, 1]; end
                    valid = true;
            end
            obj.privValid = valid;
        end
        
        function SetDynamicMask(obj, path, name)
            if ~exist(path, 'file')
                error('File not found.')
            end
            if isempty(obj.MaskWinPtr)
                error('Must supply a PTB window pointer before a dynamic mask can be loaded.')
            end
            if ~exist('name', 'var') || isempty(name)
                name = 'NEW_AOI';
            end
            % attempt to load
            try
                [obj.privMaskMovPtr, obj.privMaskMovDur,...
                    obj.privMaskMovFPS, obj.privMaskW,...
                    obj.privMaskH, obj.privMaskMovFrames] =...
                    Screen('OpenMovie', obj.MaskWinPtr, path);
            catch ERR
                error('Error whilst loading video: \n\n%s', ERR.message)
            end
            obj.privType = 'DYNAMIC MASK';
            obj.privMaskMovOpen = true;
            obj.MaskPath = path;
            obj.Name = name;
            obj.CheckValid
%             stimAR = obj.privStimMovW / obj.privStimMovH;
%             if stimAR ~= drawAR
%                 if stimAR > 1           % wide
%                     obj.privStimScale = [1, 1 / stimAR];
%                 elseif stimAR < 1       % tall
%                     obj.privStimScale = [1 / stimAR, 1];
%                 end
%             end
        end
        
        function SetStaticMask(obj, path, name)
            if ~exist(path, 'file')
                error('File not found.')
            end
            if isempty(obj.MaskWinPtr)
                error('Must supply a PTB window pointer before a static mask can be loaded.')
            end            
            if ~exist('name', 'var') || isempty(name)
                name = 'NEW_AOI';
            end            
            % attempt to load
            try
                img = imread(path);
                obj.privMaskW = size(img, 2);
                obj.privMaskH = size(img, 1);
                obj.privMaskImg = img;
                obj.MaskPath = path;
                obj.privType = 'STATIC MASK';
                obj.privMaskImgTexPtr = Screen('MakeTexture',...
                    obj.MaskWinPtr, img);
                obj.CheckValid
            catch ERR
                error('Error loading static mask:\n\n%s', ERR.message)
            end
        end
    
        function set.Type(obj, val)
            if ~any(strcmpi(val, {'RECT', 'MASK'}))
                error('Type must be RECT or MASK.')
            end
            obj.privType = val;
            obj.CheckValid
        end
        
        function set.Rect(obj, val)
            if ~isvector(val) && length(val) ~= 4
                error('Rect must be a vector of length four [x1, y1, x2, y2]')
            end
            obj.privRect = val;
            obj.CheckValid
        end
        
        function val = get.Rect(obj)
            val = obj.privRect;
        end
        
        function val = get.Type(obj)
            val = obj.privType;
        end
        
        function set.Colour(obj, val)
            if ~isvector(val) || length(val) ~= 3
                error('Colour must be a three element vector, [R G B]')
            end
            if any(val > 255) || any(val < 0)
                error('All RGB colour values must be in the range 0 - 255')
            end
            val = round(val);
            obj.privColourOnDefault = false;
            obj.Colour = val;
        end
        
        function val = get.ColourOnDefault(obj)
            val = obj.privColourOnDefault;
        end
        
        function set.OnsetTime(obj, val)
            if ~isnumeric(val)
                error('Onset time must be numeric.')
            end
            if val < 0
                error('Onset time must be positive')
            end
            obj.OnsetTime = val;
        end
        
        function set.OffsetTime(obj, val)
            if ~isnumeric(val)
                error('Offset time must be numeric.')
            end
            obj.OffsetTime = val;
        end        
%         function set.Alpha(obj, val)
%             if ~isscalar(val)
%                 error('Alpha value must be scalar.')
%             end
%             if val > 255 || val < 0
%                 error('Alpha values must be in the range of 0 - 255')
%             end
%             obj.Alpha = val;
%         end
        
    end
    
end