function [mask] = roiRGB(img, colour, tolerance)

    if size(img, 3) ~= length(colour)
        mask = [];
        error('Number of colour channels in image does not match those in colour argument.')
    end
    
    if ~exist('tolerance', 'var') || isempty(tolerance)
        tolerance = 2;
    end
    
    % extract each colour channel separately
    numCol = length(colour);
    tmp = false(size(img));
    for c = 1:numCol
        colRange = [colour(c) - tolerance, colour(c) + tolerance];
        tmp(:, :, c) = roicolor(img(:, :, c), colRange(1), colRange(2));
    end
        
    % join them back together with AND
    mask = tmp(:, :, 1) & tmp(:, :, 2) & tmp(:, :, 3);
    
end