function plotGaze2(mb, tb, eb, fb, hParent)

    % defaults
    averageEyes = false;

    % check if fixtaions have been supplied
    if ~exist('fb', 'var') || isempty(fb)
        fb = [];
        fixationsPresent = false;
    else
        fixationsPresent = true;
    end
    
    % check if a parent has been supplied
    if ~exist('hParent', 'var') || isempty(hParent)
        hParent = figure;
    end
    
    % make time vector
    t = double(tb(:, 1) - tb(1, 1)) / 1e6;
    
    % remove offscreen samples of gaze
    mb = etFilterGazeOnscreen(mb);
    
    % get x and y data
    gxl = mb(:, 7);
    gyl = mb(:, 8);
    pl = mb(:, 12);
    gxr = mb(:, 20);
    gyr = mb(:, 21);
    pr = mb(:, 25);
    [gx, gy, p] = etAverageEyeBuffer(mb);
    
    % x gaze
    spX = subplot(2, 3, 1:2);
    pos_spX = get(spX, 'position');
    set(spX, 'position', [0.05, pos_spX(2:4)]);
    switch averageEyes
        case true
            scX = scatter(t, gx, 5);
        case false
            scX = scatter(t, gxl, 5);
            hold on
            scatter(t, gxr, 5);
    end
    

end