function [lx, ly, lz, rx, ry, rz] = etHeadPos_getCoords(mb)

    % preallocate
    numSamps = size(mb, 1);
    lx = nan(numSamps, 1);
    ly = nan(numSamps, 1);
    lz = nan(numSamps, 1);
    rx = nan(numSamps, 1);
    ry = nan(numSamps, 1);
    rz = nan(numSamps, 1);

    % get indexes for eye validity
    bothEyes = all(mb(:, [13, 26]) == 0, 2);
    
    % left eye
    lx(bothEyes) = mb(bothEyes, 1);
    ly(bothEyes) = mb(bothEyes, 2);
    lz(bothEyes) = mb(bothEyes, 3);
    
    % right eye
    rx(bothEyes) = mb(bothEyes, 14);
    ry(bothEyes) = mb(bothEyes, 15);
    rz(bothEyes) = mb(bothEyes, 16);
    
end