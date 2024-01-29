function t = etTimeBuffer2Secs(tb)

    % if empty timebuffer, time vector is empty
    if isempty(tb)
        t = [];
        return
    end
    
    % zero timebuffer, convert to secs
    t = double(tb(:, 1) - tb(1, 1)) / 1e6;
    
end