function salMakeAOIFeatureMaps(inPath, outPath, aoi_def, fps, dontBlur, tolerance)

    % takes a folder of colour AOI masks (colour images with each AOI
    % feature in a particular colour - e.g. export from Apple Motion) and
    % converts each AOI to a binary, black and white, feature map. 
    % Separate folders are created in outPath for each feature. Inside each
    % folder, one output image is written per features for each input image
    %
    % n.b. if your input images have been made a weird size (padded with
    % extra bits of canvas) then use etPh2_TrimMotionFrames first to trim
    % them
    
    if ~exist('dontBlur', 'var') || isempty(dontBlur)
        dontBlur = false;
    end

    % define AOIs
    if ~exist('aoi_def', 'var') || isempty(aoi_def)
        aoi_def = {...
        %   AOI             Feature Name,       Colour List
            'FACE',         'aoi_face',         {[249, 37, 2], [254, 252, 0], [62, 250, 0], [249, 64, 255]}                     ;...
            'OUTER FACE',   'aoi_outerface',    {[249, 37, 2]}                                                                  ;...
            'EYES',         'aoi_eyes',         {[254, 252, 0]}                                                                 ;...
            'MOUTH',        'aoi_mouth',        {[62, 250, 0]}                                                                  ;...
            'NOSE',         'aoi_nose',         {[249, 64, 255]}                                                                ;...
            'BODY',         'aoi_body',         {[27, 51, 255], [249, 37, 2], [254, 252, 0], [62, 250, 0], [249, 64, 255]}      ;...                                             ;...
            'HANDS',        'aoi_hands',        {[253, 128, 9]}                                                                 ;...
            'BGPEOPLE',     'aoi_bgpeople',     {[69, 253, 255], [67, 246, 255]}                                                ;...
            'BG',           'aoi_bg'            {[]}                                                                            ;...
            };
    end
    
    if ~exist('tolerance', 'var') || isempty(tolerance)
        tolerance = 20;
    end
    
    numDef = size(aoi_def, 1);

    wb = waitbar(0, 'Setting up');
    
    % check input args
    if ~exist('inPath', 'var') || isempty(inPath)
        error('Input file not found.')
    end
    
    if ~exist('outPath', 'var') || isempty(outPath)
        error('Output path not found.')
    end
    
    if ~exist('fps', 'var') || isempty(fps) || ~isnumeric(fps)
        fps = 25;
        warning('Assuming default of 25fps, if this is wrong, specify the correct value as an input argument.')
    end
    
    % read input folder
    d = dir([inPath, filesep, '*.png']);
    
    % set filename details
    vidName = 'video_v3.avi';
    framePad = '00000';
    frameName = 'frame';
    
    % make output folders, create video writers
    out = cell(numDef, 1);
    vw = cell(numDef, 1);
    for def = 1:numDef
        
        % make path
        out{def} = [outPath, filesep, aoi_def{def, 2}];
        
        % if path doesn't exist, try to create it
        if ~exist(out{def}, 'dir')
            try
                mkdir(out{def})
            catch ERR
                rethrow ERR
            end
        end
        
        % make a videowriter, set fps and open for writing
        vw{def} =...
            VideoWriter([out{def}, filesep, vidName], 'Uncompressed AVI');
        vw{def}.FrameRate = fps;
        open(vw{def});
        
    end    
     
    % loop through each frame and process colour masks to feature masks
    counter = 0;
    for f = 1:length(d)
        
        counter = counter + 1;
        if mod(counter, 15) == 0
            wb = waitbar(f / length(d), wb, 'Processing');
        end
    
        % read image, convert to 16-bit colour
%         img = im2uint8(imread([inPath, filesep, d(f).name]));
        img = imread([inPath, filesep, d(f).name]);

        % make blank inverse mask for background (i.e. the inverse of all
        % the AOIs). This will be updated for each AOI definition. 
        bg_inv = zeros(size(img, 1), size(img, 2));

        % split into features, write frame to video
        feat = cell(numDef, 1);
        for def = 1:numDef
            
            % if this AOI def is not BG (background) then loop through any
            % masks and split the colour image, otherwise invert the
            % background mask and use that instead
            if ~strcmpi(aoi_def{def, 1}, 'BG')
                
                % for each colour value (mask), get a binary ROI and OR it with
                % all other masks (to allow for multiple AOIs to be combined
                % into one feature)
                numMasks = length(aoi_def{def, 3});
                roi = false(size(img, 1), size(img, 2));
                for mask = 1:numMasks
                    colour = aoi_def{def, 3}{mask};
                    roi = roi | roiRGB(img, colour, tolerance);
                end
                feat{def} = double(roi);
                
                % dilate and apply gaussian filter
                if ~dontBlur
                    feat{def} = etBlurImage(feat{def}, 2, [34.544, 25.908],...
                        [800, 600], 60);
                end
                
                % update background mask
                bg_inv = bg_inv + feat{def};
                bg_inv(bg_inv > 1) = 1;                
            
            else
                
                feat{def} = 1 - bg_inv;
                
            end
            
            % write frames
%             imwrite(feat{def}, [out{def}, filesep, frameName,...
%                 LeadingString(framePad, f), '.png']);
            writeVideo(vw{def}, feat{def});
            
            % if on final frame, close video file
            if f == length(d)
                close(vw{def});
            end
        
        end
        
    end
    
    close(wb)
    
end