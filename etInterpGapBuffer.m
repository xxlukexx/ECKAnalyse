function mb = etInterpGapBuffer(mb, tb, maxGapMs)

    % determine sample rate
    [~, msPerS] = etDetermineSampleRate(tb);
    maxSamp = round(maxGapMs / msPerS);

    % get gaze data
    lx = mb(:, 7)';
    ly = mb(:, 8)';
    rx = mb(:, 20)';
    ry = mb(:, 21)';

    % interp
    try lx = interp1gap(lx, maxSamp); catch; end
    try ly = interp1gap(ly, maxSamp); catch; end
    try rx = interp1gap(rx, maxSamp); catch; end
    try ry = interp1gap(ry, maxSamp); catch; end

    % store results
    mb(:, [7:8, 20:21]) = [lx', ly', rx', ry'];

end