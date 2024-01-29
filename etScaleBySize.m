function [mainBufferOut] = etScaleBySize(mainBuffer, currentSizeCm,...
    newSizeCm, dontReFilter)

    if ~all(size(currentSizeCm) == [1, 2])
        error('Monitor size must be a 1 x 2 vector [width, height].')
    end

    if ~all(size(newSizeCm) == [1, 2])
        error('Monitor size must be a 1 x 2 vector [width, height].')
    end
    
    if ~exist('dontReFilter', 'var')
        dontReFilter = false;
    end
    
    % put dimensions in easily read variables
    mWidth = currentSizeCm(1);
    mHeight = currentSizeCm(2);
    wWidth = newSizeCm(1);
    wHeight = newSizeCm(2);
    
%     % remove gaze points that are offscreen
%     mainBuffer = etFilterGazeOnscreen(mainBuffer);
    
    % subtract mid-point from data
    mainBuffer(:, 7) = mainBuffer(:, 7) - .5;
    mainBuffer(:, 8) = mainBuffer(:, 8) - .5;
    mainBuffer(:, 20) = mainBuffer(:, 20) - .5;
    mainBuffer(:, 21) = mainBuffer(:, 21) - .5;   
    
    % work out scaling factors for x and y
    scaleX = mWidth / wWidth;
    scaleY = mHeight / wHeight;
    
    % scale gaze data
    mainBuffer(:, 7) = mainBuffer(:, 7) * scaleX;
    mainBuffer(:, 8) = mainBuffer(:, 8) * scaleY;
    mainBuffer(:, 20) = mainBuffer(:, 20) * scaleX;
    mainBuffer(:, 21) = mainBuffer(:, 21) * scaleY;
    
    % re-centre
    mainBuffer(:, 7) = mainBuffer(:, 7) + .5;
    mainBuffer(:, 8) = mainBuffer(:, 8) + .5;
    mainBuffer(:, 20) = mainBuffer(:, 20) + .5;
    mainBuffer(:, 21) = mainBuffer(:, 21) + .5;
    
    % refilter to remove gaze points outside the window limit
    
    if ~dontReFilter
        mainBufferOut = etFilterGazeOnscreen(mainBuffer);
    else
        mainBufferOut = mainBuffer;
    end
    
end