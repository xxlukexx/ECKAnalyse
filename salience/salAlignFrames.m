function [x, y, frameTimes, frameNums] = salAlignFrames(mb, tb, eb,...
    ftLabel)

    if ~exist('ftLabel', 'var') || isempty(ftLabel)
        ftLabel = 'NATSCENES_FRAME_FRAME_CALC';
    end
    
    x = {};
    y = {};
    frameTimes = [];
    frameNums = [];
    
    % loop through an event buffer, extract frame times, and look up
    % corresponding [x, y] coords from the main buffer. Since the framerate
    % of the video is lower than the sampling rate of ET data, x and y are
    % cell arrays of vectors. 
    
    % Each element of the array corresponds to a
    % frame. Each element of the vector corresponds to a sample of eye
    % tracking data. So if the video was recorded at 30fps, and the ET data
    % at 60Hz for 100 frames, x will be a cell array of 100 elements, each
    % containing a vector of two elements (60 / 30), corresponding to the
    % two x samples in the ET data that were closest to a particular frame
    % of video

    % filterevents for calculate frame times
    frameEvents = etFilterEvents(eb, ftLabel, true);
    if isempty(frameEvents)
        return
%         error('No calculated frame times found.')
    end
    numFrames = size(frameEvents, 1);
    
    % average eyes
    mb = etAverageEyeBuffer(mb);
    
    % preallocate output vars
    x = cell(numFrames, 1);
    y = cell(numFrames, 1);
    frameNums = zeros(numFrames, 1);
    frameTimes = zeros(numFrames, 1);
    
    % get frame number, and timestamp of movie (frame time) for all
    % frames. There two different formats that may be used for this,
    % deal with these separately
    sampleEvent = frameEvents{1, 3};
    if size(sampleEvent, 2) == 2
        % frame number is embedded in the text label of the event, and
        % frame time is a separate data field. e.g.
        % NATSCENES_FRAME_fn    [ft]
        parts = cellfun(@(x) strsplit(x{1}, '_'),...
            frameEvents(:, 3), 'uniform', false);
        frameNums = cellfun(@(x) str2double(x{end}), parts);
    elseif size(sampleEvent, 2) == 3
        % frame number and frame time are both data fields, e.g.
        % NATSCENES_FRAME       [ft]    [fn]
        frameTimes = cellfun(@(x) x{2}, frameEvents(:, 3));
        frameNums = cellfun(@(x) x{3}, frameEvents(:, 3));
    end    
    
    % get x, y coords for each frame. Take the nearest neighbour samples to
    % each frame (rather than just the sample that corresponds to that
    % frame). 
    for f = 1:numFrames
        
        % get eye tracker timestamp for this frame, look up sample number
        % for this timestamp
        etTime = frameEvents{f, 2};
        s1 = etTimeToSample(tb, etTime);
        
        % get eye tracker timestamp for next frame, look up sample number
        % for this timestamp. If this is the end of the frames, take the
        % final sample of the buffer. Otherwise, subtract one from the
        % sample number, as we want all samples between the current frame
        % and JUST BEFORE the next one
        if f < numFrames
            etTimeNext = frameEvents{f + 1, 2};
            s2 = etTimeToSample(tb, etTimeNext) - 1;  
        elseif f == numFrames
            s2 = s1;
        else
            error('Unexpected configuration of frame number within buffer - debug!')
        end
        
        % get all [x, y] coords for the range of samples aligned to the
        % current frame
        x{f} = mb(s1:s2, 7);
        y{f} = mb(s1:s2, 8);
        
    end

end

%         % get frame number, and timestamp of movie (frame time) for this
%         % frame. There two different formats that may be used for this,
%         % deal with these separately
%         sampleEvent = frameEvents{f, 3};
%         if size(sampleEvent, 2) == 2
%             % frame number is embedded in the text label of the event, and
%             % frame time is a separate data field. e.g.
%             % NATSCENES_FRAME_fn    [ft]
%             type = 'EmbeddedFrameNumber';
%             parts = strsplit(frameEvents{f, 3}{1}, '_');
%             frameNums(f) = str2double(parts{end});
%             frameTimes(f) = frameEvents{f, 3}{2};
%         elseif size(sampleEvent, 2) == 3
%             % frame number and frame time are both data fields, e.g.
%             % NATSCENES_FRAME       [ft]    [fn]
%             type = 'DataLabelFrameNumber';
%             frameNums(f) = frameEvents{f, 3}{3};
%             frameTimes(f) = frameEvents{f, 3}{2};
%         end
        