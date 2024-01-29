function [vel] = etCalculateVelocity(mb, screenWidth, screenHeight)
   
    if ~exist('monitorWidthCm', 'var') || isempty(screenWidth)
        screenWidth = 34;
    end
    
    if ~exist('monitorHeightCm', 'var') || isempty(screenHeight)
        screenHeight = 26;
    end
    
    % clean up
    mb = etFilterGazeOnscreen(mb);
    mb = etFilterHeadDistance(mb);
    
    % remove monocular/missing samples
    mono = mb(:, 13) == 0 & mb(:, 26) == 0;

    % average eyes
    [~, ~, ~, gx] = etAverageEyeData(mb(:, 7), mb(:, 20));
    [~, ~, ~, gy] = etAverageEyeData(mb(:, 8), mb(:, 21));
    [~, ~, ~, gd] = etAverageEyeData(mb(:, 3), mb(:, 16));

    % convert distance from mm to cm
    gd = gd / 10;
    
    % take mean of distance data
    gd = nanmean(gd);
       
    % rescale relative coords to visual angles (via radians) in degrees
    visang_radx = 2 * atan(screenWidth / 2 ./ gd);
    visang_rady = 2 * atan(screenHeight / 2 ./ gd);
    visang_degx = visang_radx * (180/pi);
    visang_degy = visang_rady * (180/pi);
    gx = gx .* visang_degx;
    gy = gy .* visang_degy;

    % calculate inter-sample distances and vel 
    gxDist = abs(gx(2:end) - gx(1:end - 1));
    gyDist = abs(gy(2:end) - gy(1:end - 1));
    vel = sqrt((gxDist .^ 2) + (gyDist .^ 2));

end