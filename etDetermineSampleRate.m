function [sRate, msPerS] = etDetermineSampleRate(timeBuffer)

    if isempty(timeBuffer)
        warning('Time buffer is empty.')
        sRate = nan;
        msPerS = nan;
        return
    end
    
    % look for jumps
    tb = double(timeBuffer(:, 1));
    jumpCritMs = 100;
    delta = [nan; tb(2:end) - tb(1:end - 1)];
    ol = detectOutliers(delta, 5) | delta > jumpCritMs * 1000;
    delta(ol) = [];
    
    % sample rate is reciprocal of mean inter-sample delta
    msPerS = nanmean(delta) / 1e6;
    sRate = 1 / msPerS;

end