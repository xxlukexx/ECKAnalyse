function etDrawGazePTB(winPtr, mb, tb, res, curTime)

    % colours
    col_left    = [066, 133, 244];
    col_right   = [125, 179, 066];
    col_avg     = [213, 008, 000];
    % radius (px) of gaze points
    radius = 5;
    % get sampling rate
    sr = etDetermineSampleRate(tb);
    % decay time (s) 
    decayTime = .25;
    % number of samples to go back
    decaySamples = round(decayTime * sr);
    % alpha increment 
    alphaInc = 255 / decaySamples;

%     % remove missing data
%     mb = etPreprocess(mb, 'removeoffscreen', true, 'removemissing', true);
%     missing = any(isnan(mb(:, [7, 8, 20, 21])), 2);
%     mb(missing, :) = [];

    % convert current time to sample
    tb(:, 1) = tb(:, 1) - tb(1, 1);
    if curTime < 0, curTime = 0; end
    s2 = etTimeToSample(tb, curTime * 1e6);
    s1 = s2 - decaySamples;
    if s1 < 1, s1 = 1; end

    % convert gaze to pixels
    gx_l = round(mb(s1:s2, 7) * res(1));
    gy_l = round(mb(s1:s2, 8) * res(2));
    gx_r = round(mb(s1:s2, 20) * res(1));
    gy_r = round(mb(s1:s2, 21) * res(2));
    gx_a = round((gx_l + gx_r) / 2);
    gy_a = round((gy_l + gy_r) / 2);
    numSamps = length(gx_l);
    
    % computer alpha values
    a_range = (0:alphaInc:255)';
    if length(a_range) > numSamps
        a_range = a_range(1:numSamps);
    end
    
    % reshape for PTB
    rect = [...
        [(gx_l' - radius); (gy_l' - radius); (gx_l' + radius); (gy_l' + radius)],...
        [(gx_r' - radius); (gy_r' - radius); (gx_r' + radius); (gy_r' + radius)],...
        [(gx_a' - radius); (gy_a' - radius); (gx_a' + radius); (gy_a' + radius)]];

    % create a colour range that fades out over time, reshape for PTB
    col = [...
        repmat(col_left,     numSamps, 1), a_range;...
        repmat(col_right,    numSamps, 1), a_range;...
        repmat(col_avg,      numSamps, 1), a_range];

    Screen('FillRect', winPtr, col', rect);
    
end