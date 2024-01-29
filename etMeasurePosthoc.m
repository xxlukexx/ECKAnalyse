function res = etMeasurePosthoc(file_data, screenWidth, screenHeight, path_plots)
    
% setup
    
    % default empty output var
    res = table;
    
    % check data file exists
    if ~exist(file_data, 'file')
        error('File not found.')
    end
    
    % default to 17" monitor if screen width and height are not specified
    if ~exist('screenWidth', 'var') || isempty(screenWidth) ||...
            ~exist('screenHeight', 'var') || isempty(screenHeight)
        screenWidth = 345;
        screenHeight = 259;
        warning('Either one of both of screenWidth or screenHeight were not specified. Defaulting to 17" monitor.')
    end
        
    
    % load data
    tmp = load(file_data);
    data = tmp.data;
    
    % make output filename for plots 
    if exist('path_plots', 'var') && ~isempty(path_plots)
        file_plot = fullfile(path_plots, sprintf('phc_%s_%s.png',...
            data.ParticipantID, data.Schedule));
        doPlot = true;
    else
        doPlot = false;
    end
    
    % find phc events
    ev = etFilterEvents2(data.EventBuffer, 'POSTHOC_CALIBRATION*');
    if isempty(ev), return, end
    numEvents = size(ev, 1);
    
% phc sends an event after the measurement has been taken, so we need
% to go back in time to get the gaze data for the duration of the
% measurement itself. Default length is 1.3 seconds. 

    % get times of phc events
    offset = cell2mat(ev(:, 2));
    
    % subtract 1.3 seconds (via conversion to uS)
    onset = offset - (1.0 * 1e6);
    
% get gaze data for each event

    % convert timestamps to sample numbers
    onset_samp = arrayfun(@(x) etTimeToSample(data.TimeBuffer, x), onset);
    offset_samp = arrayfun(@(x) etTimeToSample(data.TimeBuffer, x), offset);
    
    % get gaze
    gaze = arrayfun(@(on, off) data.MainBuffer(on:off, :), onset_samp,...
        offset_samp, 'uniform', false);
    
    % extract left/right eye x and y coords
    lx = cellfun(@(q) q(:, 7), gaze, 'uniform', false);
    ly = cellfun(@(q) q(:, 8), gaze, 'uniform', false);
    rx = cellfun(@(q) q(:, 20), gaze, 'uniform', false);
    ry = cellfun(@(q) q(:, 21), gaze, 'uniform', false);
    
    % get median distance from screen
    screenDist = cellfun(@(g) nanmedian(g(:, 3)), gaze);
    
% get location of each phc point. These are the first and second values in
% the data field of the event, after the 'POSTHOC_CALIBRATION' label

    % get x, y coords of each calib point
    px = cellfun(@(x) x{2}, ev(:, 3));
    py = cellfun(@(x) x{3}, ev(:, 3));

    % empty vars accuracy/precision
    lacc = nan(numEvents, 1);
    lprec = nan(numEvents, 1);
    racc = nan(numEvents, 1);
    rprec = nan(numEvents, 1);
    
    for p = 1:numEvents
       
        % convert gaze to degrees
        [lx{p}, ly{p}] = norm2deg(lx{p}, ly{p}, screenWidth,...
            screenHeight, screenDist(p));
        [rx{p}, ry{p}] = norm2deg(rx{p}, ry{p}, screenWidth,...
            screenHeight, screenDist(p));
        
        % convert points to degrees
        [px(p), py(p)] = norm2deg(px(p), py(p), screenWidth,...
            screenHeight, screenDist(p));
        
        % calculate inter-sample velocity for all gaze points, in deg per
        % samples
        lvel = sqrt((diff(lx{p}) .^ 2) + (diff(ly{p}) .^ 2));
        rvel = sqrt((diff(lx{p}) .^ 2) + (diff(ly{p}) .^ 2));

        % convert degrees per sample to deg per second
        lvel = lvel * etDetermineSampleRate(data.TimeBuffer);
        rvel = rvel * etDetermineSampleRate(data.TimeBuffer);

        % filter for gaze points with velocity > 50 deg/s to remove
        % saccades
        maxDegPerS = 50;
        lsac = lvel > maxDegPerS;
        rsac = rvel > maxDegPerS;
        lx{p}(lsac) = nan;
        ly{p}(lsac) = nan;
        rx{p}(rsac) = nan;
        ry{p}(rsac) = nan;
        
        % calculate accuracy - mean offset from all gaze points to calib
        % point
        lxoff = lx{p} - px(p);
        lyoff = ly{p} - py(p);
        ldis = sqrt((lxoff .^ 2) + (lyoff .^ 2));
        lacc(p) = nanmean(ldis);
        lprec(p) = nanrms(ldis);
        
        rxoff = rx{p} - px(p);
        ryoff = ry{p} - py(p);
        rdis = sqrt((rxoff .^ 2) + (ryoff .^ 2));
        racc(p) = nanmean(rdis);
        rprec(p) = nanrms(rdis);        
        
    end
    
% plot
  
    if doPlot
        
        % don't plot if values within range (temp)
        if any(lacc > 3) || any(racc > 3)

            fig = figure;
            scatter(px, py, 500, lines(numEvents))
            hold on
            cellfun(@(x, y) scatter(x, y), lx, ly)
            cellfun(@(x, y) scatter(x, y), rx, ry)
            export_fig(file_plot, '-r130')
            delete(fig)
            
        end
        
    end
    
% store

    res.ID = repmat({data.ParticipantID}, numEvents, 1);
    res.Timepoint = repmat({data.Schedule}, numEvents, 1);
    res.LocalTime = cell2mat(ev(:, 1));
    res.RemoteTime = cell2mat(ev(:, 2));
    res.PointX = px;
    res.PointY = py;
    res.LeftAccuracy = lacc;
    res.LeftPrecision = lprec;
    res.RightAccuracy = racc;
    res.RightPrecision = rprec;
    res.NumSamples = cellfun(@(x) size(x, 1), gaze);
    res.LeftNumUsedSamples = cellfun(@(x) sum(~isnan(x)), lx);
    res.RightNumUsedSamples = cellfun(@(x) sum(~isnan(x)), rx);
    
end