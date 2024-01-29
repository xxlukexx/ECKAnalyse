function [jumpFound, jumpIdx] = etDetectJumpBuffer(timeBuffer)

    delta = [0; timeBuffer(2:end, 1) - timeBuffer(1:end - 1, 1)];
    delta = double(delta);
    m = mean(delta);
    sd = std(delta);
    crit = m + (sd * 3);
    jumpFound = max(delta) > crit;
    jumpIdx = delta > crit;
    
end