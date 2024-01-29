function [gazeOut] = etFilterHeadDistance(mainBuffer, minDistance)

    if ~exist('minDistance', 'var') || isempty(minDistance)
        minDistance = 100;
    end

    gazeOut = mainBuffer;
    
    % left eye x, y, z
    gazeOut(gazeOut(:, 3) <= minDistance, 3) = nan;

    % right eye
    gazeOut(gazeOut(:, 16) <= minDistance, 16) = nan;

end