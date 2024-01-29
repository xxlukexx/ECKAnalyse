function etHeatmap3(cfg)

    % Draws a still image or video, optionally with stimuli, and overlays
    % eye tracking data as a heatmap
    %
    % Accepts a cfg struct as the only input argument:
    %
    %   cfg.outputpath          Path to write heatmap output (image or
    %                           video) to
    %   cfg.outputtype          Type of heatmap to make, VIDEO or IMAGE
    %   cfg.outputvideoformat   Optional format of output video, defaults
    %                           to MPEG-4
    %   cfg.outputvideores      Optional resolution of output video.
    %                           Defaults to 600 pixels wide.
    %   cfg.mainbuffer          Cell array of main buffers 
    %   cfg.timebuffer          Cell array of time buffers
    %   cfg.eventbuffer         Optional cell array of event buffers
    %   cfg.fixationbuffer      Optional cell array of fixation buffers
    %   cfg.stimtype            type of stimulus to overlay gaze on,
    %                           VIDEO or IMAGE
    %   cfg.stimpath            Optional path to image or video to draw
    %                           heatmap on top of
    %   cfg.fps                 Optional, only valid if cfg.stimtype is
    %                           VIDEO and cfg.alignframetimes = false. If
    %                           not set, will default to 25fps
    %   cfg.alignframetimes     Logical, only valid for VIDEO when an
    %                           event buffer has been passed
    %   cfg.heatmapres          Resolution of heatmap. Defaults to 75
    %                           pixels wide. Higher numbers will be slower.
    %   cfg.heatmapar           Optional aspect ratio of heatmap. Defaults
    %                           16:9. If cfg.outputvideores is not set,
    %                           this aspect ratio will be used to calculate
    %                           the vertical height in pixels of the output
    %                           video. 
    %   cfg.groupmembership     Vector containing numerical indices
    %                           representing group membership. Must be of
    %                           the same length as the buffer cell arrays.
    %                           Optional, if no groups present can be
    %                           passed as empty or ignored.
    %   cfg.grouplabels         Cell array of strings, with a label for
    %                           each group. Must have the same number of
    %                           entried as the maximum value in
    %                           cfg.groupmembership. 
    %   cfg.status              Optional ECKStatus object for reporting
    %                           progress
    
    %% interrogate cfg
    
    if ~exist('cfg', 'var') || ~isstruct(cfg) || isempty(cfg)
        error('Must supply a cfg struct.')
    end
    
    % make all cfg fields lowercase
    cfg = structFieldsToLowercase(cfg);
    
    % check output type    
    if ~isfield(cfg, 'outputtype') || isempty(cfg.outputtype) ||...
            ~any(strcmpi(cfg.outputtype, {'IMAGE', 'VIDEO'}))
        error('Must supply cfg.outputtype as either VIDEO or IMAGE')
    else
        outputType = cfg.outputtype;
    end  
    
    % check for valid buffers
    if ~isfield(cfg, 'mainbuffer') || isempty(cfg.mainbuffer) ||...
            ~iscell(cfg.mainbuffer)
        error('Must supply cfg.mainBuffer as cell array')
    else
        mb = cfg.mainbuffer;
    end
    
    if ~isfield(cfg, 'timebuffer') || isempty(cfg.timebuffer) ||...
            ~iscell(cfg.timebuffer)
        error('Must supply cfg.timeBuffer as cell array')
    else
        tb = cfg.timebuffer;
    end    

    % eventbuffer is an optional argument, so set a flag as to whether it
    % is present or not
    if ~isfield(cfg, 'eventbuffer') || isempty(cfg.eventbuffer) ||...
            ~iscell(cfg.eventbuffer)
        ebPresent = false;
    else
        eb = cfg.eventbuffer;
        ebPresent = true;
    end
    
    % fixbuffer is an optional argument, so set a flag as to whether it
    % is present or not
    if ~isfield(cfg, 'fixationbuffer') || isempty(cfg.fixationbuffer) ||...
            ~iscell(cfg.fixationbuffer)
        fbPresent = false;
        fb = [];
    else
        fbPresent = true;
        fb = cfg.fixationbuffer;
    end
    
    % check that the same length of buffers have been passed for each
    % buffer
    if ebPresent, lengthEb = length(eb); else lengthEb = length(mb); end
    if fbPresent, lengthFb = length(gb); else lengthFb = length(mb); end
    if ~isequal(length(mb), length(tb), lengthEb, lengthFb)
        error('Lengths of all buffers must be equal.')
    end
    numData = length(mb);
    
    % check stim type
    stimTakeFirstFrame = false;
    stimConvertImageToVideo = false;
    if ~isfield(cfg, 'stimtype') || isempty(cfg.stimtype) ||...
            ~any(strcmpi(cfg.stimtype, {'IMAGE', 'VIDEO'}))
        error('Must supply cfg.stimtype as either VIDEO or IMAGE')
    else
        stimType = cfg.stimtype;
        % if stimType and outputType don't match, set some flags to
        % determine what to do 
        if ~isequal(outputType, stimType)
            if strcmpi(outputType, 'IMAGE') && strcmpi(stimType, 'VIDEO')
                % output is IMAGE but stim is VIDEO, so take first frame of
                % video to overlay heatmap on
                stimTakeFirstFrame = true;
            elseif strcmpi(outputType, 'VIDEO') && strcmpi(stimType,...
                    'IMAGE')
                % output is VIDEO but stim is IMAGE, so repeat the image on
                % all frames out output video
                stimConvertImageToVideo = true;
            end
        end     
    end    
    
    % check whether align frametimes is set
    if ~isfield(cfg, 'alignframetimes') || isempty(cfg.alignframetimes) ||...
            ~islogical(cfg.alignframetimes)
        
        % we are not aligning frametimes:
        alignFT = false;
        % if not aligning frames, we need to know the target fps for the
        % ouput video. Default to 25fps if not specified
        if ~isfield(cfg, 'fps') || isempty(cfg.fps)
            fps = 25;
        else
            if ~strcmpi(outputType, 'VIDEO')
                warning('cfg.fps will be ignored unless cfg.outputtype is VIDEO.')
            end
            fps = cfg.fps;
        end
        
    else
        
        % we are aligning frametimes:
        if ~strcmpi(stimType, 'VIDEO')
            % if outputType is not VIDEO, ignore request to align
            % frametimes
            warning('cfg.alignframetimes was set, but cfg.stimtype is not VIDEO - setting will be ignored.')
            alignFT = false;
        else
            alignFT = cfg.alignframetimes;
        end
        % if an event buffer was not passed, we cannot align frames so
        % throw an error
        if ~ebPresent
            error('If you wish to align frametimes, you must pass cfg.eventbuffers')
        end
        % if fps was passed, but we are aligning frametimes, ignore fps
        % because we will calculate it from the frametimes
        if isfield(cfg, 'fps')
            warning('cfg.alignframetimes was set, so cfg.fps will be calculated from frametimes.')
        end
    end
    
    % check group settings - must be the same number of groups as buffers,
    % and as group labels
    if ~isfield(cfg, 'groupmembership') || isempty(cfg.groupmembership)
            
        grpsDefined = false;
        grpMember = ones(size(mb));
        
    else
        
        % check number of groups
        grpMember = cfg.groupmembership;    
        if ~isequal(length(grpMember), length(mb), length(tb), length(eb))
            error('cfg.groupmembership must the same size as buffer cell arrays.')
        end
        grpsDefined = true;
        
        % check group labels
        if ~isfield(cfg, 'grouplabels') 
            grpLabsDefined = false;
        else
            if ~iscell(cfg.grouplabels)
                error('cfg.grouplabels must be a cell array of strings.')
            end
            grpLabs = cfg.grouplabels;
            if length(grpLabs) ~= max(unique(grpMember))
                error('Number of cfg.grouplabels must match length of cfg.groupmembership, and of buffer cell arrays.')
            end
            grpLabsDefined = true;
        end
        
    end    
    grpNum = max(unique(grpMember));

    % check stimpath
    if ~isfield(cfg, 'stimpath') || isempty(cfg.stimpath)
        
        stimPathPresent = false;
        stimPath = [];
        
    else
        
        % check that stimPath exists
        if ~exist(cfg.stimpath, 'file')
            error('cfg.stimpath not found: \n%s', cfg.stimpath)
        end
        stimPath = cfg.stimpath;
        
        % check format of provided stim
        switch stimType
            
            case 'VIDEO'
                % try getting video metadata from the provided file. If
                % this fails, then it means it wasn't a video
                try
                    stimInf = mmfileinfo(stimPath);
                    stimPathPresent = true;
                catch ERR
                    switch ERR.identifier
                        case 'MATLAB:audiovideo:VideoReader:unsupportedImage'
                            error('cfg.stimtype is set to VIDEO, but cfg.stimpath points to an image file.')
                        case 'MATLAB:audiovideo:VideoReader:InitializationFailed'
                            error('cfg.stimtype is set to VIDEO but cfg.stimpath could not be identiifed as a video.')
                        otherwise 
                            error('Could not read video data from cfg.stimpath:\n\t%s',...
                                ERR.message)
                    end
                end
                
            case 'IMAGE'
                % try getting image metadata from the provided file. If
                % this fails, it means it wasn't an image
                try
                    stimInf = imageinfo(stimPath);
                    stimPathPresent = true;
                catch ERR
                    switch ERR.identifier
                        case 'images:imageinfo:couldNotReadFile'
                            error('cfg.stimtype is set to IMAGE, but cfg.stimpath could not be indentified as an image.')
                        otherwise
                            error('Could not read image data from cfg.stimpath:\n\t%s',...
                                ERR.message)                    
                    end
                end
                
        end

    end
    
    % check heatmap aspect ratio
    if ~isfield(cfg, 'heatmapar') || isempty(cfg.heatmapar)
        ar = 16 / 9;
    else
        ar = cfg.heatmapar(1) / cfg.heatmapar(2);
    end
    
    % check heatmap resolution
    if ~isfield(cfg, 'heatmapres') || isempty(cfg.heatmapres)
        % determine vertical resolution by aspect ratio
        hmRes = [30, round(75 / ar)];
    else
        hmRes = cfg.heatmapres;
        % calculate aspect ratio
        ar = cfg.heatmapres(1) / cfg.heatmapres(2);
    end
    
    % set heatmap parameters
    hmParams = {0:1 / (hmRes(2) - 1):1, 0: 1 / (hmRes(1) - 1):1};
    
    % check output path
    if ~isfield(cfg, 'outputpath') || isempty(cfg.outputpath)
        error('Must set cfg.outputpath.')
    else
        outputPath = cfg.outputpath;
    end
    
    % check output video format - default to MP4 if not passed
    if ~isfield(cfg, 'outputvideoformat') ||...
            isempty(cfg.outputvideoformat)
        outputVideoFormat = 'MPEG-4';
    else
        if ~strcmpi(outputType, 'VIDEO')
            warning('cfg.outputvideoformat will be ignored if cfg.outputtype is not VIDEO')
        end
        outputVideoFormat = cfg.outputvideoformat;
    end
    
    % check output video resolution
    if ~isfield(cfg, 'outputvideores') || isempty(cfg.outputvideores)
        outputRes = [600, round(600 / ar)];
    else
        if ~strcmpi(outputType, 'VIDEO')
            warning('cfg.outputvideores will be ignored if cfg.outputtype is not VIDEO')
        end
        outputRes = cfg.outputvideores;
    end
        
    % check for ECKStatus object
    if ~isfield(cfg, 'status') || ~isa(cfg.status, 'ECKStatus')
        stat = [];
        statPresent = false;
    else
        stat = cfg.status;
        stat.Status = sprintf('etHeatmap3: Setting up...\n');
        statPresent = true;
    end
    
    %% prepare stim to overlay heatmap on
    
    if stimPathPresent
        switch stimType
            case 'VIDEO'
                % open stim video
                vr = VideoReader(stimPath);
                stimNumframes = round(vr.Duration * vr.FrameRate);
                % if outputType is IMAGE then take just the first frame
                if stimTakeFirstFrame
                    fr = readFrame(vr);
                    close(vr)
                end
            case 'IMAGE'
                % open image
                fr = imread(stimPath);
        end                              
    end 
    
    %% preprocess
    
    if strcmpi(outputType, 'VIDEO')
    
        % deal with timestamps - if aligning frame times, do this; otherwise
        % zero time buffers and assume first sample of each buffer is already
        % aligned

        ft = cell(numData, 1);  % frame times
        fn = cell(numData, 1);  % frame numbers
        gx = cell(numData, 1);  % smoothed/aligned gaze data
        gy = cell(numData, 1);

        if alignFT

            % extract frametimes from each eventbuffer
            discard = false(numData, 1);
            for d = 1:numData

                % filter offscreen gaze
                mb{d} = etFilterGazeOnscreen(mb{d});

                % align gfaze data to video frames
                [x, y, ft{d}, fn{d}] =...
                    salAlignFrames(mb{d}, tb{d}, eb{d}, 'NATSCENES_FRAME');
                
                % if no frametimes were present, salAlignFrames will return
                % empty x and y. Check for this an skip if it is the case
                if isempty(x)
                    discard(d) = true;
                    continue
                end

                % take mean gaze point for each frame
                gx{d}(1:length(x), 1) = cellfun(@nanmean, x);
                gy{d}(1:length(y), 1) = cellfun(@nanmean, y);
                
                if statPresent
                    stat.Status = sprintf('Aligning frames %.1f%%...\n',...
                        (d / numData) * 100);
                end

            end
            
            % discard data with no events (unable to align frametimes)
            gx(discard) = [];
            gy(discard) = [];
            fn(discard) = [];
            ft(discard) = [];
            grpMember(discard) = [];
            
            % calculate fps from frame times
            fps = mean(cellfun(@(x, y)...
                (x(end) - x(1)) / (y(end) - y(1)), fn, ft));

        else
            
            % align data 
            for d = 1:numData
                
                % calculate duration of ET data in seconds
                dur = double(tb{d}(end, 1) - tb{d}(1, 1)) / 1e6;
                
                % calculate number of needed frames
                tmpNumFrames = round(dur * fps);
                spf = 1 / fps;
                
                % calculate virtual frame times
                ft{d} = (0:spf:dur)';
                fn{d} = (1:tmpNumFrames)';
                
                % convert frame times to ET remote times
                firstTimeRemote = tb{d}(1, 1);
                ft_rem = firstTimeRemote + uint64((ft{d} * 1e6));
                
                % get sample numbers from remote times
                st = arrayfun(@(x) etTimeToSample(tb{d}, x), ft_rem);
                
                % get gaze data from samples
                mb{d} = etFilterGazeOnscreen(mb{d});
                [x, y, ~] = etAverageEyeBuffer(mb{d});
                gx{d} = x(st);
                gy{d} = y(st);
                
                if statPresent
                    stat.Status = sprintf('Aligning frames %.1f%%...\n',...
                        (d / numData) * 100);
                end               
                
            end

        end
        
        % put data into matrices
        x = unevencell2mat(gx);
        y = unevencell2mat(gy);
        ftm = unevencell2mat(ft);
        
        % get frametime deltas
        ftd = ftm(2:end, :) - ftm(1:end - 1, :);        
        
        % find frametimes with jumps, for exclusion
        ftJump = nanmean(ftd, 1) - mode(ftd(:)) > .00001;
        x(:, ftJump) = [];
        y(:, ftJump) = [];
        ftm(:, ftJump) = [];
        grpMember(ftJump) = [];
        
        % align matrices
        [ftm, alignRows, alignIdx] = alignMatrix(ftm, 2);
        x = alignMatrix(x, 2, alignRows, alignIdx);
        y = alignMatrix(y, 2, alignRows, alignIdx);
        
        % get unique frametimes
        allFt = ftm(:);
        ftu = unique(allFt(~isnan(allFt) & allFt ~= 0));
        
        % smooth gaze data
        x = medfilt1(x, 5);
        y = medfilt1(y, 5);
        
        %% render

        % make video writer
        vw = VideoWriter(outputPath, outputVideoFormat);
        open(vw);  
        
        % calculate max number of frames across all participants.
        % Participants with fewer than this number will have missing
        % frames dropped
        numFrames = length(ftu);
        
        % define group colours for heatmap
        grpCol = lines(grpNum);
        
        % loop through frames, make heatmaps, write to video
        for f = 1:numFrames
            
            % report progress
            if statPresent
                stat.Status = sprintf('Rendering video %.1f%%...\n',...
                    (f / numFrames) * 100);
            end
            
            % get frame of stimulus
            blankNeeded = false;
            if stimPathPresent
                if ~stimTakeFirstFrame
                    if ftu(f) ~= -1
                        vr.CurrentTime = ftu(f);
                    end
                    if hasFrame(vr)
                        fr = readFrame(vr);
                    else
                        blankNeeded = true;
                    end
                    fr = imresize(fr, fliplr(outputRes));
                end         
            else
                blankNeeded = true;
            end
            if blankNeeded
                fr = zeros(outputRes(2), outputRes(1), 3, 'uint8');
            end
            fr = im2double(fr);

%             % preallocate heatmap storage
%             hm = zeros(hmRes(2), hmRes(1), grpNum);
            
            % loop through groups (if defined)
            for g = 1:grpNum
                
                % get indices of data belonging to the current group
                grpIdx = grpMember == g;
                
                % make heatmap for this group
                f1 = f - 10;
                if f1 < 1, f1 = 1; end
                f2 = f + 10;
                if f2 > numFrames, f2 = numFrames; end
                
                tmp =...
                    hist3([y(f, grpIdx)', x(f, grpIdx)'], hmParams);
                
                % normalise                
                tmp = mat2gray(tmp);
                
                % colour
                hm = ind2rgb(uint8(tmp * 255), cmap(grpCol(g, :), 255, 0, 20));
                
                % resize
                hm = imresize(hm, fliplr(outputRes));
%                 colblock(1, 1, 1) = grpCol(g, 1);
%                 colblock(1, 1, 2) = grpCol(g, 2);
%                 colblock(1, 1, 3) = grpCol(g, 3);
%                 hm = imresize(colblock, fliplr(outputRes));
                alpha = imresize(tmp, fliplr(outputRes));
                
                % blur
                hm = imgaussfilt(hm, 5);
%                 alpha = imgaussfilt(alpha, 5);
                alpha = mat2gray(alpha);
                alpha(alpha < .3) = 0;
                alpha(alpha >= .3) = 1;
                
                % overlay on frame
                fr(:, :, 1) =...
                    fr(:, :, 1) .* (1 - alpha) +...
                    (hm(:, :, 1) .* alpha);
                fr(:, :, 2) =...
                    fr(:, :, 2) .* (1 - alpha) +...
                    (hm(:, :, 2) .* alpha);                
                fr(:, :, 3) =...
                    fr(:, :, 3) .* (1 - alpha) +...
                    (hm(:, :, 3) .* alpha); 

            end            
            
          
            
%             % preallocate heatmap storage
%             hm = zeros(hmRes(2), hmRes(1), 3, grpNum);
%             alpha = zeros(hmRes(2), hmRes(1), grpNum);
%             
%             % loop through groups (if defined)
%             for g = 1:grpNum
%                 
%                 % get indices of data belonging to the current group
%                 grpIdx = grpMember == g;
%                 
%                 % make heatmap for this group
%                 tmp = hist3([y(f, grpIdx)', x(f, grpIdx)'], hmParams);
%                 tmp = (tmp / (max(tmp(:)))) * 1;
%                 tmp = imdilate(tmp, 40);
% %                 tmp(tmp > 1) = 1;
%                 
%                 % make greyscale heatmap by repeating intensity values on
%                 % all three colours channels + alpha
%                 hm(:, :, :, g) = repmat(tmp, [1, 1, 1, 3]);
%                 alpha(:, :, g) = tmp;
%                 
%                 % apply group colour 
%                 hm(:, :, 1, g) = hm(:, :, 1, g) * grpCol(g, 1);
%                 hm(:, :, 2, g) = hm(:, :, 2, g) * grpCol(g, 2);
%                 hm(:, :, 3, g) = hm(:, :, 3, g) * grpCol(g, 3);
%                 
%             end
%             
%             hm = imresize(hm, fliplr(outputRes));
%             hm = imgaussfilt(hm, 10);
% 
%             hmFrame = imresize(hmFrame, fliplr(outputRes));
%             alpha = imresize(alpha, fliplr(outputRes));
%             hmFrame = imgaussfilt(hmFrame, 10);
%             alpha = imgaussfilt(alpha, 10);
%             
%             % get frame of stimulus
%             if stimPathPresent
%                 if ~stimTakeFirstFrame
%                     if ftu(f) ~= -1
%                         vr.CurrentTime = ftu(f);
%                     end
%                     if hasFrame(vr)
%                         fr = readFrame(vr);
%                     else
%                         fr = zeros(vr.Height, vr.Width, 3, 'uint8');
%                     end
%                     fr = imresize(fr, fliplr(outputRes));
%                     hm(:, :, :, end + 1) = im2double(fr);
%                 end            
%             end
%             
%             
%             
%             % combine heatmaps from all groups
%             if grpNum > 1
%                 hmFrame = blendImages(hm, alpha);
%                 alpha = blendImages(alpha);
%                 
%                 hmFrame = mean(hm, 4);
%                 alpha = mean(alpha, 3);
%             else
%                 hmFrame = hm; 
%             end
% 
%             % resize and gaussian blur
% 
% 
% 
%             % normalise
%             alpha = alpha / max(alpha(:));
%             hmFrame = (hmFrame / max(hmFrame(:))) * 1;
%             chopIdx = hmFrame > 1;
%             hmFrame(chopIdx) = 1;
%             
%             % make alpha 60% max
% %             alpha = hmFrame(:, :, 4);
% %             alpha(alpha > .8) = .8;
% %             hmFrame(:, :, 4) = alpha;
%             
% 
%                 
%                 % overlay heatmap on stimulus
%                 fr(:, :, 1) =...
%                     fr(:, :, 1) .* (1 - alpha) +...
%                     (hmFrame(:, :, 1) .* alpha);
%                 fr(:, :, 2) =...
%                     fr(:, :, 2) .* (1 - alpha) +...
%                     (hmFrame(:, :, 2) .* alpha);                
%                 fr(:, :, 3) =...
%                     fr(:, :, 3) .* (1 - alpha) +...
%                     (hmFrame(:, :, 3) .* alpha); 
%                 
%             end
            
            fr = uint8(fr * 255);

            writeVideo(vw, fr);

        end
        
        close(vw)
        
    end
            
end